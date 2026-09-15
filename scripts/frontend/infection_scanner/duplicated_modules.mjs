import path from 'node:path';

const toPosixRelative = (rootPath, absolutePath) =>
  path.relative(rootPath, absolutePath).split(path.sep).join('/');

const isThirdParty = (absolutePath) => absolutePath.includes(`${path.sep}node_modules${path.sep}`);

const requestsVue3 = (source) => Boolean(source) && source.includes('?vue3');

const newTrail = () => ({ infected: new Map(), clean: new Map() });
const laneOf = (trail, infected) => (infected ? trail.infected : trail.clean);

export function simulateLanes({ graph, seeds, isInfectable }) {
  const infected = new Set();
  const clean = new Set();
  const trail = newTrail();
  const queue = [];

  for (const seed of seeds) {
    const lane = laneOf(trail, seed.infected);
    if (lane.has(seed.file)) continue;
    lane.set(seed.file, null);
    queue.push({ file: seed.file, infected: seed.infected });
  }

  while (queue.length) {
    const step = queue.shift();
    (step.infected ? infected : clean).add(step.file);

    for (const edge of graph[step.file]?.imports ?? []) {
      const target = edge.resolved;
      if (!target) continue;

      // An explicit `?vue3` import is infected even under a clean importer.
      const targetInfected = requestsVue3(edge.source) || (step.infected && isInfectable(target));
      const lane = laneOf(trail, targetInfected);
      if (lane.has(target)) continue;

      lane.set(target, step);
      queue.push({ file: target, infected: targetInfected });
    }
  }

  return { infected, clean, trail };
}

const chainTo = (trail, file) => {
  const chain = [];
  let step = { file, infected: false };

  while (step) {
    chain.unshift(step);
    step = laneOf(trail, step.infected).get(step.file) ?? null;
  }
  return chain;
};

// Null when the whole chain is clean: there is nothing above it to force.
const sinkOf = (chain) => {
  const index = chain.findIndex((step) => !step.infected);
  return index > 0 ? chain[index].file : null;
};

export function findDuplicatedModules({
  graph,
  pages,
  isInfectable,
  rootPath,
  duplicationExpected = [],
}) {
  const isDuplicationExpected = new Set(duplicationExpected);
  const findings = [];

  for (const { entry, flagState, seeds } of pages) {
    const name = flagState ? `${entry} (${flagState})` : entry;
    const present = seeds.filter((seed) => graph[seed.file]);
    if (!present.length) continue;

    const { infected, clean, trail } = simulateLanes({ graph, seeds: present, isInfectable });

    for (const file of infected) {
      if (!clean.has(file)) continue;
      // CONTEXT_ALIASES duplicates node_modules on purpose.
      if (isThirdParty(file)) continue;

      const singletons = graph[file]?.singletons ?? [];
      if (!singletons.length) continue;

      const module = toPosixRelative(rootPath, file);
      if (isDuplicationExpected.has(module)) continue;

      const chain = chainTo(trail, file);
      findings.push({
        page: name,
        entry,
        seeds: present.map((seed) => toPosixRelative(rootPath, seed.file)),
        module,
        singletons,
        sink: sinkOf(chain) && toPosixRelative(rootPath, sinkOf(chain)),
        chain: chain.map((step) => ({
          file: toPosixRelative(rootPath, step.file),
          infected: step.infected,
        })),
      });
    }
  }

  return findings.sort((a, b) => a.page.localeCompare(b.page) || a.module.localeCompare(b.module));
}
