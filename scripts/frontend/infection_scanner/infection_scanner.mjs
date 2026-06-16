#!/usr/bin/env node
import { createRequire } from 'node:module';
import path from 'node:path';
import fs from 'node:fs';
import { createServer } from 'node:http';
import { execSync } from 'node:child_process';
import { analyze, createResolver } from './analyze.mjs';

const cjsRequire = createRequire(import.meta.url);
const ROOT_PATH = path.resolve(import.meta.dirname, '..', '..', '..');
const JS_ROOT = path.join(ROOT_PATH, 'app/assets/javascripts');
const OUTPUT_PATH = path.join(ROOT_PATH, 'tmp', 'infection_scanner.json');

// --- Alias resolution (loaded from webpack config) ---

function buildAliasMap() {
  const webpackConfig = cjsRequire(path.join(ROOT_PATH, 'config/webpack.config.js'));
  const { CONTEXT_ALIASES } = cjsRequire(
    path.join(ROOT_PATH, 'config/helpers/context_aliases_shared'),
  );
  const aliases = { ...webpackConfig.resolve.alias };
  // Context aliases represent "vue3 mode" resolution — the infection plugin
  // applies these at runtime.  Merge them as exact-match aliases ($ suffix)
  // so the scanner follows the same resolution paths.
  for (const [key, target] of Object.entries(CONTEXT_ALIASES)) {
    aliases[`${key}$`] = target;
  }
  return aliases;
}

const aliasMap = buildAliasMap();

// Single shared resolver instance, used both for entrypoint discovery and
// (transparently, inside `analyze()`) for the graph walk.
const resolver = createResolver({
  aliasMap,
  rootPath: ROOT_PATH,
  fallbackResolve: (specifier, fromDir) => {
    try {
      return cjsRequire.resolve(specifier, { paths: [fromDir] });
    } catch {
      return null;
    }
  },
});

// --- Entry discovery ---

function discoverEntries() {
  const { generateEntries } = cjsRequire(path.join(ROOT_PATH, 'config/webpack.helpers'));
  const defaultEntries = ['./main'];
  const generated = generateEntries({ defaultEntries });

  const manual = {
    sentry: ['./sentry/index.js'],
    coverage_persistence: ['./entrypoints/coverage_persistence.js'],
    performance_bar: ['./entrypoints/performance_bar.js'],
    jira_connect_app: ['./jira_connect/subscriptions/index.js'],
    sandboxed_mermaid_v11: ['./lib/mermaid_v11.js'],
    redirect_listbox: ['./entrypoints/behaviors/redirect_listbox.js'],
    sandboxed_swagger: ['./lib/swagger.js'],
    super_sidebar: ['./entrypoints/super_sidebar.js'],
    tracker: ['./entrypoints/tracker.js'],
    analytics: ['./entrypoints/analytics.js'],
    graphql_explorer: ['./entrypoints/graphql_explorer.js'],
  };

  const all = { default: defaultEntries, ...manual, ...generated };

  const dummyFromFile = path.join(JS_ROOT, '__entry__.js');
  const entrypoints = {};
  for (const [name, files] of Object.entries(all)) {
    const last = Array.isArray(files) ? files[files.length - 1] : files;
    const resolved = resolver.resolveModule(last, dummyFromFile);
    if (resolved) {
      entrypoints[name] = resolved;
    }
  }
  return entrypoints;
}

// --- Infection specifiers (loaded from context aliases) ---

const INFECTION_SPECIFIERS = (() => {
  const { CONTEXT_ALIASES } = cjsRequire(
    path.join(ROOT_PATH, 'config/helpers/context_aliases_shared'),
  );
  return Object.keys(CONTEXT_ALIASES);
})();

// --- JSON output ---

function writeOutput(result) {
  const dir = path.dirname(OUTPUT_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(result, null, 2));
  console.log(`[vue3-infection-scanner] Written to ${OUTPUT_PATH}. Done.`);
}

// --- Web server ---

function getRelPath(absPath) {
  if (!absPath) return absPath;
  return path.relative(ROOT_PATH, absPath);
}

function buildSubgraph(graph, rootFile) {
  const nodes = new Map();
  const links = [];
  const visited = new Set();
  const queue = [rootFile];
  visited.add(rootFile);

  while (queue.length) {
    const file = queue.shift();
    const entry = graph[file];
    if (!nodes.has(file)) {
      let type = 'js';
      if (file.includes('/node_modules/')) {
        type = 'node_module';
      } else if (file.endsWith('.vue')) {
        type = 'vue';
      }

      nodes.set(file, {
        id: file,
        rel: getRelPath(file),
        type,
        dynamicImport: false,
        appRoot: entry ? entry.appRoot : false,
        infected: entry ? entry.infected : false,
        infectionSource: entry?.infectionReasons?.some((s) => s.file === file) || false,
        infectionSourceReason:
          entry?.infectionReasons?.find((s) => s.file === file)?.reason || null,
        infectionReasons: entry?.infectionReasons
          ? entry.infectionReasons.map((s) => ({ file: getRelPath(s.file), reason: s.reason }))
          : [],
        infectionReasonCount: entry?.infectionReasonCount || 0,
      });
    }
    const edges = entry ? entry.imports : [];
    for (const edge of edges) {
      if (edge.resolved) {
        links.push({ source: file, target: edge.resolved, dynamic: edge.dynamic });
        if (!visited.has(edge.resolved)) {
          visited.add(edge.resolved);
          queue.push(edge.resolved);
        }
      }
    }
  }

  for (const link of links) {
    if (link.dynamic && nodes.has(link.target)) {
      nodes.get(link.target).dynamicImport = true;
    }
  }

  return { nodes: [...nodes.values()], links };
}

const LOADING_HTML = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="5">
  <title>Infection Scanner - Analyzing...</title>
  <style>
    body { font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #1a1a2e; color: #e0e0e0; }
    .spinner { border: 4px solid #333; border-top: 4px solid #e94560; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin-right: 16px; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .container { display: flex; align-items: center; }
  </style>
</head>
<body>
  <div class="container"><div class="spinner"></div><h2>Analysis in progress... page will refresh automatically.</h2></div>
</body>
</html>`;

const UI_HTML_PATH = path.join(import.meta.dirname, 'infection_scanner-ui.html');

const subgraphCache = new Map();
let entryStatsCache = null;

function computeEntryStats(entrypoints, graph) {
  const stats = {};
  const triggerEntryCount = new Map();

  for (const [name, file] of Object.entries(entrypoints)) {
    const visited = new Set();
    const queue = [file];
    visited.add(file);
    let infectionSources = 0;
    let infected = 0;
    let appRoots = 0;
    let total = 0;
    const entryInfectionSources = new Set();

    while (queue.length) {
      const f = queue.shift();
      const isNm = f.includes('/node_modules/');
      const entry = graph[f];
      if (entry) {
        if (!isNm) {
          total += 1;
          if (entry.appRoot) {
            appRoots += 1;
          }
          if (entry.infected) {
            infected += 1;
            if (entry.infectionReasons && entry.infectionReasons.some((s) => s.file === f)) {
              infectionSources += 1;
              entryInfectionSources.add(f);
            }
          }
        }
        for (const imp of entry.imports) {
          if (imp.resolved && !visited.has(imp.resolved) && graph[imp.resolved]) {
            visited.add(imp.resolved);
            queue.push(imp.resolved);
          }
        }
      }
    }

    for (const t of entryInfectionSources) {
      triggerEntryCount.set(t, (triggerEntryCount.get(t) || 0) + 1);
    }

    stats[name] = { infectionSources, infected, appRoots, total };
  }

  const topTriggers = [...triggerEntryCount.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 20)
    .map(([file, count]) => {
      const entry = graph[file];
      const reason = entry?.infectionReasons?.find((s) => s.file === file)?.reason || null;
      return { file: getRelPath(file), reason, entryCount: count };
    });

  return { stats, topInfectionSources: topTriggers };
}

let analysisResult = null;
let analysisRunning = false;

function startServer() {
  const PORT = 9131;
  const server = createServer((req, res) => {
    const url = new URL(req.url, `http://localhost:${PORT}`);

    if (url.pathname === '/subgraph' && analysisResult) {
      const rootFile = url.searchParams.get('root');
      if (!rootFile || !analysisResult.graph[rootFile]) {
        res.writeHead(404);
        res.end('File not found in graph');
        return;
      }
      if (!subgraphCache.has(rootFile)) {
        subgraphCache.set(rootFile, JSON.stringify(buildSubgraph(analysisResult.graph, rootFile)));
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(subgraphCache.get(rootFile));
      return;
    }

    if (url.pathname === '/hybrid-list' && analysisResult) {
      const rootFile = url.searchParams.get('root');
      if (!rootFile || !analysisResult.graph[rootFile]) {
        res.writeHead(404);
        res.end('File not found in graph');
        return;
      }
      const { graph } = analysisResult;
      const visited = new Set();
      const queue = [rootFile];
      visited.add(rootFile);
      const projectTriggers = [];
      const projectTargets = [];
      const nmTriggers = [];
      const nmTargets = [];
      const appRoots = [];

      while (queue.length) {
        const f = queue.shift();
        const entry = graph[f];
        if (entry) {
          const isNm = f.includes('/node_modules/');
          if (entry.appRoot && !isNm) {
            appRoots.push({ id: f, file: getRelPath(f) });
          }
          if (entry.infected) {
            const isSrc =
              entry.infectionReasons && entry.infectionReasons.some((s) => s.file === f);
            const reason = isSrc ? entry.infectionReasons.find((s) => s.file === f).reason : null;
            const item = { id: f, file: getRelPath(f), reason };
            if (isSrc) {
              (isNm ? nmTriggers : projectTriggers).push(item);
            } else {
              (isNm ? nmTargets : projectTargets).push(item);
            }
          }
          for (const imp of entry.imports) {
            if (imp.resolved && !visited.has(imp.resolved) && graph[imp.resolved]) {
              visited.add(imp.resolved);
              queue.push(imp.resolved);
            }
          }
        }
      }

      const result = { projectTriggers, projectTargets, nmTriggers, nmTargets, appRoots };
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result));
      return;
    }

    if (analysisRunning || !analysisResult) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(LOADING_HTML);
      return;
    }

    if (url.pathname === '/' || url.pathname === '/index.html') {
      const template = fs.readFileSync(UI_HTML_PATH, 'utf-8');
      if (!entryStatsCache) {
        console.log('[vue3-infection-scanner] Computing entry stats...');
        entryStatsCache = computeEntryStats(analysisResult.entrypoints, analysisResult.graph);
        console.log('[vue3-infection-scanner] Entry stats computed.');
      }
      const dataJson = JSON.stringify({
        entrypoints: analysisResult.entrypoints,
        entryStats: entryStatsCache.stats,
        topInfectionSources: entryStatsCache.topInfectionSources,
      });
      const dataScript = `const DATA = ${dataJson};`;
      const html = template.replace('/* DATA_PLACEHOLDER */', dataScript);
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(html);
      return;
    }

    res.writeHead(404);
    res.end('Not found');
  });

  server.listen(PORT, () => {
    console.log(`[vue3-infection-scanner] Server running at http://localhost:${PORT}`);
    try {
      const openCmd = process.platform === 'darwin' ? 'open' : 'xdg-open';
      execSync(`${openCmd} http://localhost:${PORT}`);
    } catch {
      /* ignore if browser open fails */
    }
  });
}

// --- Main ---

async function runAnalysis() {
  analysisRunning = true;

  console.log('[vue3-infection-scanner] Discovering entrypoints...');
  const entrypoints = discoverEntries();
  console.log(`[vue3-infection-scanner] Found ${Object.keys(entrypoints).length} entrypoints`);

  console.log('[vue3-infection-scanner] Building import graph...');
  const result = await analyze({
    rootPath: ROOT_PATH,
    entrypoints,
    infectionSpecifiers: INFECTION_SPECIFIERS,
    aliasMap,
    fallbackResolve: (specifier, fromDir) => {
      try {
        return cjsRequire.resolve(specifier, { paths: [fromDir] });
      } catch {
        return null;
      }
    },
    onProgress: (parsed, total) => {
      process.stderr.write(
        parsed === total
          ? `\r[vue3-infection-scanner] Parsed ${total}/${total} files. Done.\n`
          : `\r[vue3-infection-scanner] Parsed ${parsed}/${total} files...`,
      );
    },
  });

  // analyze() produces the annotated graph; surface aggregate counts.
  let appRoots = 0;
  let infected = 0;
  for (const entry of Object.values(result.graph)) {
    if (entry.appRoot) appRoots += 1;
    if (entry.infected) infected += 1;
  }
  console.log(`[vue3-infection-scanner] App roots: ${appRoots} files`);
  console.log(
    `[vue3-infection-scanner] Infected: ${infected} / ${Object.keys(result.graph).length} files`,
  );

  writeOutput(result);
  analysisResult = result;
  analysisRunning = false;
  return result;
}

const mode = process.argv[2];

if (mode === 'web') {
  runAnalysis();
  startServer();
} else {
  runAnalysis().catch((err) => {
    console.error(err);
    process.exitCode = 1;
  });
}
