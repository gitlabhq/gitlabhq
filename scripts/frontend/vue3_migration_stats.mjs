#!/usr/bin/env node

/**
 * Reports Vue 3 migration progress and team ownership across page
 * entrypoints.
 *
 * The script is in two halves. `collectEntrypoints` gathers everything
 * known about every page entrypoint into one array of records; the
 * `render*` functions are pure views over that array and do no gathering
 * of their own. Adding a view should never mean touching the collector.
 *
 * The entry set is taken from the bundler's own entry generator, so the
 * denominator matches what Webpack/Vite actually emit.
 *
 * Each entrypoint is in one of four migration states:
 *
 *   ⚪ vue2       neither of the below: the page builds as Vue 2 only
 *   🟢 rollout    `vue3_migration.yml` with `status: rollout`
 *   🟠 manual     a hand-written `?vue3` import in the page source, no YAML
 *   🔵 migrated   `vue3_migration.yml` with `status: migrated`
 *
 * The tree leaves Vue 2 pages unmarked instead, so the handful that have
 * moved stand out among the hundreds that have not.
 *
 * A flag's `default_enabled` is a separate axis, shown as its own column
 * because it cuts across both `rollout` and `manual`.
 *
 * Ownership is not declared anywhere for page entrypoints, so it is
 * inferred:
 *
 *   entrypoint → controller#action → feature_category → group
 *
 * The first hop is the naming convention the bundler and `webpack_helper`
 * already share; the second comes from `rake gitlab:feature_categories:index`;
 * the third from the handbook's `stages.yml`. Both are cached under `tmp/`.
 *
 * Size estimates how much work a page's migration is: `reachableComponentCount`
 * counts the `.vue` files the entry pulls in through the import graph, and
 * `size` buckets that into S/M/L/XL. Components rather than modules, because a
 * `.vue` file is where a Vue 3 incompatibility can live.
 *
 * It is a proxy, not a measurement: it counts components rather than weighing
 * how hard any of them is, and a component shared by two pages counts once for
 * each, so the totals across pages do not sum to the codebase.
 *
 * Because `feature_category` is declared on the *controller*, this infers
 * frontend ownership from backend ownership. Where a team owns a page's UI
 * but not its controller, the attribution is wrong. It is a starting point
 * for assigning work, not a declaration of ownership.
 *
 * Usage — every path is resolved against the repository, so it runs from
 * any directory:
 *
 *   node scripts/frontend/vue3_migration_stats.mjs             summary
 *   node scripts/frontend/vue3_migration_stats.mjs --tree      + entrypoint tree
 *   node scripts/frontend/vue3_migration_stats.mjs --owners    + ownership table
 *   node scripts/frontend/vue3_migration_stats.mjs --json      records, as JSON
 *   node scripts/frontend/vue3_migration_stats.mjs --refresh   rebuild caches
 *
 * Every flag selects a view; none of them change what is collected. The
 * first run on a cold cache boots Rails to resolve ownership and cruises the
 * import graph to size the pages, and takes a couple of minutes, whichever view
 * is asked for. Later runs are fast. Because the import graph is cached like the
 * other slow inputs, sizes are those of the checkout the cache was built from;
 * `--refresh` rebuilds it.
 *
 * The summary is printed last, after whichever listings were asked for.
 * `--owners` emits one Markdown row per entrypoint, so it can be pasted
 * into an issue or a merge request description as-is.
 *
 * Every view reports the date of the latest commit, so runs collected over
 * time can be plotted against a date axis.
 *
 * EE pages are included unless `FOSS_ONLY=1` is set, matching the
 * bundler's own behaviour.
 */

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { program } from 'commander';
import { cruise } from 'dependency-cruiser';
// eslint-disable-next-line import/no-unresolved -- This is a valid subpath export
import extractWebpackResolveConfig from 'dependency-cruiser/config-utl/extract-webpack-resolve-config';

const require = createRequire(import.meta.url);
const glob = require('glob');
const yaml = require('js-yaml');
const { generateEntries } = require('../../config/webpack.helpers');
const { loadVue3Migrations } = require('../../config/helpers/vue3_migration_loader');
const IS_EE = require('../../config/helpers/is_ee_env');

const ROOT_PATH = path.resolve(import.meta.dirname, '../..');

// dependency-cruiser keys every module by a path relative to the working
// directory, so the repository root has to be the working directory for those
// keys to be repo-relative.
process.chdir(ROOT_PATH);

program
  .description('Reports Vue 3 migration progress and team ownership across page entrypoints.')
  .option('--tree', 'list every entrypoint as a tree')
  .option('--owners', 'list every entrypoint and its owning team, as a Markdown table')
  .option('--json', 'print the underlying records instead of a report')
  .option('--refresh', 'rebuild every cached input: feature categories, stages.yml, import graph')
  .parse();

const { tree: TREE, owners: OWNERS, json: JSON_OUTPUT, refresh: REFRESH } = program.opts();

// The slow inputs are cached here: one boots Rails, one hits the network, one
// cruises the import graph. `tmp/` is fully gitignored.
const CACHE_DIR = path.join(ROOT_PATH, 'tmp/vue3_migration_stats');
const STAGES_URL = 'https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml';

const STATUS_VUE2 = 'vue2';
const STATUS_MANUAL = 'manual';
// Least to most migrated, so the summary reads as the progression it tracks.
const STATUS_ORDER = [STATUS_VUE2, 'rollout', STATUS_MANUAL, 'migrated'];

// A department is a union of sections. `stages.yml` carries a `section` per
// stage but no department: its only `department` keys sit under
// `internal_customers`, which is who a group serves rather than who it reports to.
//
// `foundations` and `developer_experience` are absent because no page entrypoint
// resolves to either; they report as unknown if that changes.
const DEPARTMENT_BY_SECTION = {
  ai: 'AI Engineering',
  analytics: 'Data / Analytics',
  cd: 'Core DevOps',
  database_excellence: 'Infrastructure Platforms',
  dev: 'Core DevOps',
  fulfillment: 'Fulfillment',
  growth: 'Growth',
  saas_production_engineering: 'Infrastructure Platforms',
  sec: 'Product Security',
  tenant_scale: 'Infrastructure Platforms',
  ci: 'Core DevOps',
  'data-science': 'Data / Analytics',
  gitlab_delivery: 'Infrastructure Platforms',
};

// Entries no route resolves to, so no `feature_category` and no stage can be
// derived for them. Only the stage is stated; the department follows from it.
const OWNERSHIP_OVERRIDES = new Map([
  ['pages.admin.ai.amazon_q_settings', { stage: 'ai_platform' }],
  ['pages.admin.application_settings.metrics_and_profiling', { stage: 'production_engineering' }],
  ['pages.admin.application_settings.network', { stage: 'security_platform' }],
  ['pages.admin.application_settings.reporting', { stage: 'analytics' }],
  ['pages.admin.dev_ops_report', { stage: 'analytics' }],
  ['pages.admin.geo', { stage: 'tenant_scale' }],
  ['pages.admin.gitlab_duo.configuration', { stage: 'ai_platform' }],
  ['pages.admin.gitlab_duo.model_selection', { stage: 'ai_platform' }],
  ['pages.admin.gitlab_duo.show', { stage: 'ai_platform' }],
  ['pages.admin.orbit.show', { stage: 'orbit' }],
  ['pages.dashboard.orbit.show', { stage: 'orbit' }],
  ['pages.explore.ai_catalog', { stage: 'agent_foundations' }],
  ['pages.gitlab_subscriptions.trials', { stage: 'growth' }],
  ['pages.gitlab_subscriptions.trials.duo_enterprise', { stage: 'growth' }],
  ['pages.gitlab_subscriptions.trials.duo_pro', { stage: 'growth' }],
  ['pages.groups.projects', { stage: 'plan' }],
  ['pages.groups.settings.gitlab_duo.configuration', { stage: 'fulfillment' }],
  ['pages.groups.settings.gitlab_duo.model_selection', { stage: 'ai_platform' }],
  ['pages.groups.settings.gitlab_duo.seat_utilization', { stage: 'fulfillment' }],
  ['pages.groups.settings.gitlab_duo.show', { stage: 'fulfillment' }],
  ['pages.groups.settings.orbit.show', { stage: 'orbit' }],
  ['pages.groups.duo_agents_platform', { stage: 'agent_foundations' }],
  ['pages.ide.index', { stage: 'create' }],
  ['pages.ide.oauth_redirect', { stage: 'create' }],
  ['pages.ldap.omniauth_callbacks', { stage: 'security_platform' }],
  ['pages.oauth.applications', { stage: 'security_platform' }],
  ['pages.omniauth_callbacks', { stage: 'security_platform' }],
  ['pages.projects.commit.rapid_diffs', { stage: 'ai_coding' }],
  ['pages.projects.duo_agents_platform', { stage: 'agent_foundations' }],
  ['pages.projects.google_cloud.configuration', { stage: 'deploy' }],
  ['pages.projects.google_cloud.databases.index', { stage: 'database_excellence' }],
  ['pages.projects.google_cloud.databases.new', { stage: 'database_excellence' }],
  ['pages.projects.google_cloud.deployments', { stage: 'deploy' }],
  ['pages.projects.google_cloud.gcp_regions', { stage: 'deploy' }],
  ['pages.projects.google_cloud.service_accounts', { stage: 'deploy' }],
]);

// ───────────────────────────────────────────────────────────────────────
// Data sources
// ───────────────────────────────────────────────────────────────────────

/**
 * The date of the latest commit, in ISO 8601, so that runs collected over
 * time can be plotted against a date axis.
 *
 * @returns {string|null} `null` outside a git checkout.
 */
const readCommitDate = () => {
  try {
    return execFileSync('git', ['log', '-1', '--format=%cI'], {
      cwd: ROOT_PATH,
      encoding: 'utf-8',
    }).trim();
  } catch {
    return null;
  }
};

/**
 * Read a slow-to-obtain artefact from `tmp/`, producing it on a miss.
 *
 * @param {string} filename
 * @param {() => Promise<string>|string} produce
 * @returns {Promise<string>}
 */
const cached = async (filename, produce) => {
  const file = path.join(CACHE_DIR, filename);
  if (!REFRESH && fs.existsSync(file)) return fs.readFileSync(file, 'utf-8');

  const contents = await produce();
  fs.mkdirSync(CACHE_DIR, { recursive: true });
  fs.writeFileSync(file, contents);
  return contents;
};

/**
 * Every routed controller action, grouped by feature category. The rake
 * task walks the real Rails route set and resolves the category through
 * the controller's superclass chain, so it is authoritative in a way that
 * grepping for the `feature_category` macro would not be.
 *
 * @returns {Promise<Record<string, Array<object>>>}
 */
const loadControllerActions = async () => {
  const raw = await cached('feature_categories_index.yml', () => {
    console.error('Booting Rails to dump feature categories (cached for later runs)…');
    return execFileSync('bundle', ['exec', 'rake', 'gitlab:feature_categories:index'], {
      cwd: ROOT_PATH,
      encoding: 'utf-8',
      maxBuffer: 128 * 1024 * 1024,
    });
  });
  // The task dumps Ruby symbol keys, which parse back as `":klass"` strings.
  return yaml.safeLoad(raw).controller_actions;
};

/**
 * Feature category to owning stage and group, plus the section each stage
 * belongs to, from the handbook's stages file. `config/feature_categories.yml`
 * is generated from the same source but flattens the group away, so it cannot
 * answer this.
 *
 * @returns {Promise<{
 *   owners: Map<string, {stage: string, group: string, owning: boolean}>,
 *   sectionByStage: Map<string, string|null>,
 * }>}
 */
const loadCategoryGroups = async () => {
  const raw = await cached('stages.yml', async () => {
    const response = await fetch(STAGES_URL);
    if (!response.ok) throw new Error(`${STAGES_URL} returned HTTP ${response.status}`);
    return response.text();
  });

  const owners = new Map();
  const sectionByStage = new Map();
  // A group can maintain a category another group owns. Ownership wins,
  // whichever order the stages happen to be declared in.
  const claim = (category, owner) => {
    const existing = owners.get(category);
    if (!existing || (owner.owning && !existing.owning)) owners.set(category, owner);
  };

  for (const [stage, definition] of Object.entries(yaml.safeLoad(raw).stages)) {
    sectionByStage.set(stage, definition.section ?? null);
    for (const [group, groupDefinition] of Object.entries(definition.groups ?? {})) {
      for (const category of groupDefinition.categories ?? []) {
        claim(category, { stage, group, owning: true });
      }
      for (const category of groupDefinition.maintained_categories ?? []) {
        claim(category, { stage, group, owning: false });
      }
    }
  }
  return { owners, sectionByStage };
};

// Only source files can be parsed for further imports. Imported assets — images,
// `.graphql` documents, stylesheets — are real dependencies but terminal ones, and
// handing a `.png` to the parser makes the cruise throw outright.
const PARSEABLE = /\.(?:js|mjs|cjs|vue)$/;

/**
 * The whole page import graph, as `module → resolved dependencies`.
 *
 * dependency-cruiser only deep-parses a `.vue` SFC's `<script>` when the file is
 * cruised as an *entry*; a `.vue` that is merely *followed* comes back as a
 * dependency-less leaf, which would truncate the graph at the first component.
 * So the walk is breadth-first, re-cruising each newly discovered level as
 * entries, and only trusts the dependencies of modules in the current batch.
 *
 * Every page entrypoint seeds one shared walk. The pages overlap heavily, so
 * this costs about as much as tracing the largest page alone.
 *
 * @returns {Promise<Map<string, string[]>>}
 */
const loadModuleGraph = async (seeds) => {
  const raw = await cached('module_graph.json', async () => {
    console.error('Cruising the page import graph (cached for later runs)…');
    const resolveOptions = await extractWebpackResolveConfig('./config/webpack.config.js');
    const cruiseOptions = {
      doNotFollow: { path: 'node_modules' },
      exclude: { path: 'node_modules' }, // NB: do NOT exclude dynamic imports
      moduleSystems: ['es6', 'cjs', 'amd'],
      enhancedResolveOptions: { extensions: ['.js', '.cjs', '.mjs', '.vue'] },
    };

    const graph = new Map();
    const walked = new Set();
    let frontier = [...seeds];

    while (frontier.length > 0) {
      const pending = frontier.filter((file) => !walked.has(file));
      pending.forEach((file) => walked.add(file));
      // Unparseable dependencies are recorded as the leaves they are, so they
      // still count towards a page's size.
      pending.filter((file) => !PARSEABLE.test(file)).forEach((file) => graph.set(file, []));

      const batch = pending.filter((file) => PARSEABLE.test(file));
      if (batch.length === 0) break;

      // Sequential by design: each level's frontier is the previous level's result.
      // eslint-disable-next-line no-await-in-loop
      const { output } = await cruise(batch, cruiseOptions, resolveOptions);
      const bySource = new Map(output.modules.map((module) => [module.source, module]));

      const next = [];
      for (const file of batch) {
        const dependencies = (bySource.get(file)?.dependencies ?? [])
          .filter((dependency) => !dependency.couldNotResolve)
          .map((dependency) => dependency.resolved);
        graph.set(file, dependencies);
        for (const dependency of dependencies) {
          if (!walked.has(dependency)) next.push(dependency);
        }
      }
      frontier = [...new Set(next)];
    }

    return JSON.stringify(Object.fromEntries(graph));
  });

  return new Map(Object.entries(JSON.parse(raw)));
};

/**
 * The `default_enabled` of every feature flag, which comes from the flag's
 * own definition rather than from `vue3_migration.yml`.
 *
 * @returns {Map<string, boolean>}
 */
const loadFlagDefaults = () => {
  const defaults = new Map();
  for (const relFile of glob.sync('{,ee/}config/feature_flags/**/*.yml', { cwd: ROOT_PATH })) {
    const doc = yaml.safeLoad(fs.readFileSync(path.join(ROOT_PATH, relFile), 'utf-8'));
    if (doc?.name) defaults.set(doc.name, doc.default_enabled === true);
  }
  return defaults;
};

// ───────────────────────────────────────────────────────────────────────
// Resolution
// ───────────────────────────────────────────────────────────────────────

// Rails derives `controller_path` from the class name. The dump's
// `source_location` cannot stand in for it: that resolves per action, so an
// EE-overridden action points at `ee/app/controllers/ee/…`, where `ee` appears twice.
const underscore = (value) =>
  value
    .replace(/([A-Z\d]+)([A-Z][a-z])/g, '$1_$2')
    .replace(/([a-z\d])([A-Z])/g, '$1_$2')
    .toLowerCase();

const controllerPathOf = (klass) =>
  underscore(klass.replace(/Controller$/, '').replace(/::/g, '/'));

/**
 * Where a controller class is defined. The dump carries a `source_location`
 * per action, but that points at the EE overlay for actions EE overrides,
 * so the class file is found from the name instead.
 *
 * @param {string} klass
 * @returns {string|null}
 */
const controllerFileOf = (klass) => {
  const relative = `${controllerPathOf(klass)}_controller.rb`;
  return (
    ['app/controllers', 'ee/app/controllers']
      .map((dir) => `${dir}/${relative}`)
      .find((file) => fs.existsSync(path.join(ROOT_PATH, file))) ?? null
  );
};

// `webpack_controller_bundle_tags` renders `create` with the `new` bundle
// and `update` with `edit`, so the same aliasing has to happen here.
const ACTION_ALIASES = { create: 'new', update: 'edit' };

/**
 * Walk a dotted path backwards to the first entry that exists.
 *
 * @param {string[]} segments
 * @param {Set<string>} known
 * @returns {string|null}
 */
const longestEntry = (segments, known) => {
  const remaining = [...segments];
  while (remaining.length > 0) {
    const candidate = `pages.${remaining.join('.')}`;
    if (known.has(candidate)) return candidate;
    remaining.pop();
  }
  return null;
};

/**
 * The entrypoint that owns a page source file: the longest ancestor
 * directory that is itself an entry. Without the ancestor walk a match in
 * `pages/projects/blob/show/index.js` would also be attributed to
 * `pages.projects`, which `generateEntries` prepends into its descendants.
 *
 * @param {string} relFile - Path relative to ROOT_PATH.
 * @param {Set<string>} known
 * @returns {string|null}
 */
const entryForFile = (relFile, known) => {
  const segments = relFile
    .replace(/^ee\//, '')
    .replace('app/assets/javascripts/pages/', '')
    .split('/');
  segments.pop();
  return longestEntry(segments, known);
};

/**
 * The entrypoint Rails would load for a controller action, mirroring
 * `app/helpers/webpack_helper.rb`.
 *
 * This has to run forwards, from action to entry. The reverse is not
 * derivable — `pages/projects/index.js` legitimately serves every
 * `Projects::*` action that has no entry of its own.
 *
 * @param {string} controllerPath
 * @param {string} action
 * @param {Set<string>} known
 * @returns {string|null}
 */
const entryForAction = (controllerPath, action, known) =>
  longestEntry([...controllerPath.split('/'), ACTION_ALIASES[action] ?? action], known);

/**
 * Every module reachable from a set of files, the files themselves included.
 *
 * A module shared by several entrypoints counts in full for each of them, not
 * divided between them: the count answers how much code one page pulls in.
 *
 * @param {string[]} seeds
 * @param {Map<string, string[]>} graph
 * @returns {Set<string>}
 */
const reachableFrom = (seeds, graph) => {
  const seen = new Set(seeds);
  const stack = [...seeds];
  while (stack.length > 0) {
    for (const dependency of graph.get(stack.pop()) ?? []) {
      if (!seen.has(dependency)) {
        seen.add(dependency);
        stack.push(dependency);
      }
    }
  }
  return seen;
};

// ───────────────────────────────────────────────────────────────────────
// Collection
// ───────────────────────────────────────────────────────────────────────

/**
 * @typedef {object} Entrypoint
 * @property {string} name - e.g. `pages.projects.blob.show`.
 * @property {string[]} fileNames - The `index.js` files this entry builds from,
 *   repo-relative, CE first. Two when EE shadows a CE entry of the same name.
 * @property {string|null} controllerFileName - The controller routing the most
 *   actions here. `null` when no route resolves to this entry.
 * @property {string} status - `migrated`, `rollout`, `manual` or `vue2`.
 * @property {string|null} featureFlag
 * @property {boolean|null} flagDefaultEnabled - `null` when unknown.
 * @property {FeatureCategory[]} featureCategories - Busiest first; the head owns the entry.
 * @property {number} reachableComponentCount - `.vue` files the entry reaches,
 *   counted whole for this entry even where another entry reaches them too.
 */

/**
 * A feature category one of an entry's routed actions belongs to, with the
 * team that owns it. `stage` and `group` need `stages.yml` to resolve, so
 * they are materialised here rather than left to the caller.
 *
 * @typedef {object} FeatureCategory
 * @property {string} name
 * @property {number} actions - Routed actions in this category resolving to the entry.
 * @property {string|null} stage
 * @property {string|null} group
 * @property {string|null} department
 */

/**
 * Everything known about every page entrypoint, in one array. Always
 * complete: which fields a view happens to read is not this function's
 * concern.
 *
 * @returns {Promise<{entrypoints: Entrypoint[], edition: string, warnings: string[]}>}
 */
async function collectEntrypoints() {
  // `generateEntries` takes the shared bootstrap modules prepended to every
  // entry (e.g. `./main`) and returns both the entry map and the bookkeeping
  // the Webpack config needs. Migrated pages also get a sibling `<entry>.vue3`,
  // excluded here so only the originals are counted.
  const { entries, entriesState } = generateEntries([]);
  const names = Object.keys(entries)
    .filter((name) => !name.endsWith('.vue3'))
    .sort();
  const known = new Set(names);
  const warnings = [];

  const migrations = loadVue3Migrations();

  /**
   * An entry's own source files, CE first. `generateEntries` prepends the
   * ancestor entries Webpack bundles in with it, so the entry's own module
   * is the last one.
   *
   * When both editions define the same entry name, EE shadows CE and
   * `generateEntries` keeps only the winner. Both are still real source:
   * the EE file is typically a wrapper that imports the CE one, so
   * reporting the wrapper alone would point at a stub and hide the page.
   *
   * @param {string} name
   * @returns {string[]}
   */
  const filesOf = (name) => {
    const imports = entries[name];
    // Drop the edition prefix (`.` for CE, `ee` otherwise) to get the path
    // relative to that edition's `app/assets/javascripts`.
    const [, ...rest] = imports[imports.length - 1].split('/');
    const relative = `app/assets/javascripts/${rest.join('/')}`;
    return ['', 'ee/']
      .map((editionRoot) => `${editionRoot}${relative}`)
      .filter((file) => fs.existsSync(path.join(ROOT_PATH, file)));
  };

  // Some pages opt into Vue 3 with a hand-written `?vue3` dynamic import
  // instead of a `vue3_migration.yml`. Every `?vue3` occurrence in the
  // codebase lives under a `pages/` directory, so a substring check over the
  // page sources finds all of them without walking the module graph.
  const manualEntries = new Map();
  const contradictory = [];
  for (const relFile of glob.sync('{,ee/}app/assets/javascripts/pages/**/*.{js,vue}', {
    cwd: ROOT_PATH,
  })) {
    const source = fs.readFileSync(path.join(ROOT_PATH, relFile), 'utf-8');
    if (!source.includes('?vue3')) continue;

    const entry = entryForFile(relFile, known);
    if (!entry) continue;
    if (migrations[entry]) {
      contradictory.push(relFile);
      continue;
    }

    const flagMatch = source.match(/gon\.features\?*\.(\w+)/);
    manualEntries.set(
      entry,
      flagMatch ? flagMatch[1].replace(/[A-Z]/g, (char) => `_${char.toLowerCase()}`) : '',
    );
  }

  const flagDefaults = loadFlagDefaults();

  // An entrypoint can serve many actions across several categories and
  // controllers — `pages.projects` spans dozens of both. Count them so the
  // dominant one can lead.
  const tally = (index, entry, key) => {
    if (!index.has(entry)) index.set(entry, new Map());
    const seen = index.get(entry);
    seen.set(key, (seen.get(key) ?? 0) + 1);
  };
  const busiest = (index, entry) =>
    [...(index.get(entry) ?? new Map())].sort(
      ([keyA, countA], [keyB, countB]) => countB - countA || keyA.localeCompare(keyB),
    );

  const categoriesByEntry = new Map();
  const controllersByEntry = new Map();
  const controllerActions = await loadControllerActions();
  for (const [category, actions] of Object.entries(controllerActions)) {
    for (const action of actions) {
      const klass = action[':klass'];
      const entry = entryForAction(controllerPathOf(klass), action[':action'], known);
      if (!entry) continue;
      tally(categoriesByEntry, entry, category);
      tally(controllersByEntry, entry, klass);
    }
  }
  const { owners: categoryGroups, sectionByStage } = await loadCategoryGroups();
  // Keyed on the stage that ends up on the record, so an overridden stage
  // carries its own department.
  const departmentOf = (stage) =>
    (stage && DEPARTMENT_BY_SECTION[sectionByStage.get(stage)]) ?? null;

  const moduleGraph = await loadModuleGraph([...new Set(names.flatMap((name) => filesOf(name)))]);

  const entrypoints = names.map((name) => {
    const status = migrations[name]
      ? migrations[name].status
      : (manualEntries.has(name) && STATUS_MANUAL) || STATUS_VUE2;
    const featureFlag = migrations[name]?.feature_flag || manualEntries.get(name) || null;

    // Busiest first, so the head is the category the entry mostly belongs to
    // and the group that owns it. Ancestor entries such as `pages.projects`
    // span several; the tail is kept so a consumer can see that.
    const override = OWNERSHIP_OVERRIDES.get(name);
    const rawCategories = busiest(categoriesByEntry, name).map(([category, actions]) => {
      const owner = categoryGroups.get(category);
      const stage = override?.stage ?? owner?.stage ?? null;
      return {
        name: category,
        actions,
        stage,
        group: override?.group ?? owner?.group ?? null,
        department: departmentOf(stage),
      };
    });
    // An override stands in for the category list when no route resolves here,
    // so an entry named in OWNERSHIP_OVERRIDES still reports its owner.
    const overrideCategories = override
      ? [
          {
            name: 'override',
            actions: 0,
            stage: override.stage ?? null,
            group: override.group ?? null,
            department: departmentOf(override.stage ?? null),
          },
        ]
      : [];
    const categories = rawCategories.length > 0 ? rawCategories : overrideCategories;

    // Nearly every entry routes to a single controller; the busiest is the
    // controller for all but the namespace-wide ancestors.
    const [[controller] = []] = busiest(controllersByEntry, name);

    const fileNames = filesOf(name);
    const reachable = reachableFrom(fileNames, moduleGraph);

    return {
      name,
      fileNames,
      controllerFileName: controller ? controllerFileOf(controller) : null,
      status,
      featureFlag,
      flagDefaultEnabled: featureFlag ? (flagDefaults.get(featureFlag) ?? null) : null,
      featureCategories: categories,
      reachableComponentCount: [...reachable].filter((file) => file.endsWith('.vue')).length,
    };
  });

  if (names.length !== entriesState.autoEntriesCount) {
    warnings.push(
      `counted ${names.length} entries but the generator reports ` +
        `${entriesState.autoEntriesCount}. An entry name may end in ".vue3".`,
    );
  }

  const indent = (values) => values.map((value) => `  ${value}`).join('\n');

  if (contradictory.length > 0) {
    warnings.push(
      `${contradictory.length} page(s) have both a vue3_migration.yml and a hand-written ` +
        `?vue3 import. The YAML wins; the manual import is redundant:\n${indent(contradictory.sort())}`,
    );
  }

  const edition = IS_EE ? 'EE' : 'FOSS';

  // The loader globs every page root regardless of edition, so a YAML can
  // describe an entry this build does not emit — either an EE page under
  // `FOSS_ONLY`, or a directory with no sibling `index.js`.
  const orphans = Object.keys(migrations).filter((entry) => !known.has(entry));
  if (orphans.length > 0) {
    warnings.push(
      `${orphans.length} vue3_migration.yml file(s) describe an entry ` +
        `this ${edition} build does not emit, and are excluded above:\n${indent(orphans.sort((a, b) => a.localeCompare(b)))}`,
    );
  }

  return { entrypoints, edition, warnings, committedAt: readCommitDate() };
}

// ───────────────────────────────────────────────────────────────────────
// Views
// ───────────────────────────────────────────────────────────────────────

const SYMBOL = {
  migrated: '🔵',
  rollout: '🟢',
  [STATUS_MANUAL]: '🟠',
  [STATUS_VUE2]: '⚪',
};
const BAR_WIDTH = 24;
const UNKNOWN = '—';

// Emoji take two terminal columns but are one or two UTF-16 code units
// depending on the character — `⚪` is one, `🟡` is two — so `String.length`
// cannot line up a column that mixes them with plain text. Every column
// that has to align goes through `pad`, not `padEnd`.
const isWide = (codePoint) =>
  (codePoint >= 0x2600 && codePoint <= 0x27bf) ||
  (codePoint >= 0x2b00 && codePoint <= 0x2bff) ||
  (codePoint >= 0x1f300 && codePoint <= 0x1f9ff);

const displayWidth = (value) =>
  [...value].reduce((total, char) => total + (isWide(char.codePointAt(0)) ? 2 : 1), 0);

const pad = (value, width) => value + ' '.repeat(Math.max(0, width - displayWidth(value)));

const bar = (count, total, width = BAR_WIDTH) =>
  '█'.repeat(total === 0 ? 0 : Math.round((count / total) * width)).padEnd(width, '░');
const percent = (count, total) => (total === 0 ? 0 : (count / total) * 100);
const onVue3 = (entry) => entry.status !== STATUS_VUE2;
// A manual entry has no `vue3_migration.yml`, so any flag it carries was
// scraped out of the page source rather than declared.
const flagInferred = (entry) => entry.status === STATUS_MANUAL && Boolean(entry.featureFlag);
// `featureCategories` is sorted busiest first, so the head is the category
// most of this entry's routed actions belong to, and the group that owns it.
const owningGroup = (entry) => {
  const [{ stage, group } = {}] = entry.featureCategories;
  return group ? `${stage}/${group}` : null;
};

const flagLabel = (entry) => entry.featureFlag ?? '';
// Abbreviate to the repo's own import aliases: `~/` for app/assets/javascripts
// and `ee/` for its EE counterpart.
const shortFileName = (fileName) =>
  fileName.replace(/^(?:(ee)\/)?app\/assets\/javascripts\//, (_, edition) =>
    edition ? `${edition}/` : '~/',
  );
const defaultLabel = (entry) => {
  if (!entry.featureFlag) return '';
  if (entry.flagDefaultEnabled === null) return '?';
  return entry.flagDefaultEnabled ? 'on' : 'off';
};

// Fixed thresholds, not percentiles, so a bucket keeps its meaning as pages migrate.
const SIZE_BUCKETS = [
  { label: 'S', upTo: 10 },
  { label: 'M', upTo: 50 },
  { label: 'L', upTo: 200 },
  { label: 'XL', upTo: Infinity },
];
const SIZE_ORDER = SIZE_BUCKETS.map(({ label }) => label);
const sizeLabel = (entry) =>
  SIZE_BUCKETS.find(({ upTo }) => entry.reachableComponentCount < upTo).label;

/**
 * A trie over the dot-separated entry names. A node can be both a directory
 * and an entrypoint (`pages.groups.work_items` is an entry and the parent of
 * `show`), so the two are tracked independently.
 *
 * @param {Entrypoint[]} entrypoints
 */
const buildTree = (entrypoints) => {
  const root = {
    label: 'pages',
    children: new Map(),
    entry: entrypoints.find(({ name }) => name === 'pages'),
  };
  for (const entrypoint of entrypoints) {
    let node = root;
    for (const segment of entrypoint.name.split('.').slice(1)) {
      if (!node.children.has(segment)) {
        node.children.set(segment, { label: segment, children: new Map() });
      }
      node = node.children.get(segment);
    }
    node.entry = entrypoint;
  }
  return root;
};

const countDirectories = (node) =>
  (node.children.size > 0 ? 1 : 0) +
  [...node.children.values()].reduce((sum, child) => sum + countDirectories(child), 0);

const sortedChildren = (node) =>
  [...node.children.values()].sort((a, b) => a.label.localeCompare(b.label));

/**
 * Every entrypoint as a tree, in the style of the `tree` command.
 *
 * @param {Entrypoint[]} entrypoints
 */
function renderTree(entrypoints) {
  const root = buildTree(entrypoints);
  const active = entrypoints.filter((entry) => onVue3(entry));

  // First pass lays out the connectors so the second can align the annotation
  // columns across every depth. The root carries no connector, so it is seeded here.
  const lines = [{ text: root.label, node: root }];
  const layout = (node, prefix, isLast) => {
    lines.push({ text: `${prefix}${isLast ? '└──' : '├──'} ${node.label}`, node });

    const children = sortedChildren(node);
    const childPrefix = prefix + (isLast ? '    ' : '│   ');
    children.forEach((child, index) => layout(child, childPrefix, index === children.length - 1));
  };
  const topLevel = sortedChildren(root);
  topLevel.forEach((child, index) => layout(child, '', index === topLevel.length - 1));

  const labelWidth = Math.max(...lines.map((line) => line.text.length)) + 2;
  const flagWidth = active.length
    ? Math.max(...active.map((entry) => flagLabel(entry).length)) + 2
    : 0;

  console.log(
    `${SYMBOL.migrated} migrated   ${SYMBOL.rollout} rollout (yml)   ` +
      `${SYMBOL[STATUS_MANUAL]} manual (?vue3 import, no yml)   unmarked = Vue 2 only`,
  );
  console.log();

  // Only entries on Vue 3 are annotated, so those rows stand out.
  for (const { text, node } of lines) {
    if (!node.entry || !onVue3(node.entry)) {
      console.log(text);
      continue;
    }
    const flag = flagLabel(node.entry);
    const annotation = `${SYMBOL[node.entry.status]} ${flag.padEnd(flagWidth)}${defaultLabel(node.entry)}`;
    console.log(`${text.padEnd(labelWidth)}${annotation}`.trimEnd());
  }
}

/**
 * Counts by migration status, then by feature flag.
 *
 * @param {Entrypoint[]} entrypoints
 */
function renderSummary(entrypoints) {
  const total = entrypoints.length;
  const active = entrypoints.filter((entry) => onVue3(entry));

  console.log();
  console.log(`${countDirectories(buildTree(entrypoints))} directories, ${total} entrypoints`);
  console.log();

  for (const status of STATUS_ORDER) {
    const count = entrypoints.filter((entry) => entry.status === status).length;
    const label = `${SYMBOL[status]} ${status}`;
    console.log(
      `  ${pad(label, 13)}${String(count).padStart(4)}  ` +
        `${percent(count, total).toFixed(1).padStart(5)}%  ` +
        `${bar(count, total)}`,
    );
  }
  console.log(
    `  ${pad('on Vue 3', 13)}${String(active.length).padStart(4)}  ` +
      `${percent(active.length, total).toFixed(1).padStart(5)}%`,
  );

  const flags = new Map();
  for (const entry of active) {
    if (!entry.featureFlag) continue;
    if (!flags.has(entry.featureFlag)) {
      flags.set(entry.featureFlag, { count: 0, inferred: false, entry });
    }
    const flag = flags.get(entry.featureFlag);
    flag.count += 1;
    flag.inferred = flag.inferred || flagInferred(entry);
  }
  const flagWidth = Math.max(...[...flags.keys()].map((flag) => flag.length));

  console.log();
  console.log(`    ${'Feature flag'.padEnd(flagWidth)}  entries  default_enabled`);
  for (const [name, flag] of [...flags].sort(
    ([nameA, flagA], [nameB, flagB]) => flagB.count - flagA.count || nameA.localeCompare(nameB),
  )) {
    const note = flag.inferred ? '  (inferred from gon.features)' : '';
    console.log(
      `    ${name.padEnd(flagWidth)}  ${String(flag.count).padStart(7)}  ${defaultLabel(flag.entry).padEnd(3)}${note}`.trimEnd(),
    );
  }

  const defaultOn = active.filter((entry) => defaultLabel(entry) === 'on').length;
  const defaultOff = active.filter((entry) => defaultLabel(entry) === 'off').length;
  console.log();
  console.log(
    `  Of the ${active.length} entrypoints on Vue 3: ${defaultOn} behind a default-on flag, ` +
      `${defaultOff} behind a default-off flag`,
  );

  // What is left, sized.
  const remaining = entrypoints.filter((entry) => !onVue3(entry));
  const sizeWidth = Math.max(...SIZE_ORDER.map((label) => label.length));
  console.log();
  console.log(`  Remaining ${remaining.length} Vue 2 entrypoints, by reachable .vue components`);
  console.log();
  console.log(`    ${pad('size', sizeWidth)}  entries  components  per entry`);
  for (const label of SIZE_ORDER) {
    const bucket = remaining.filter((entry) => sizeLabel(entry) === label);
    if (bucket.length === 0) continue;
    const counts = bucket.map((entry) => entry.reachableComponentCount);
    const components = counts.reduce((sum, count) => sum + count, 0);
    console.log(
      `    ${pad(label, sizeWidth)}  ${String(bucket.length).padStart(7)}  ` +
        `${String(components).padStart(10)}  ${Math.min(...counts)}–${Math.max(...counts)}`,
    );
  }
}

/**
 * Every entrypoint and the team it belongs to, as a Markdown table, one row
 * each, ordered by department, then group, then size with the biggest first, so
 * a group's pages sit together and lead with their largest migration.
 *
 * @param {Entrypoint[]} entrypoints
 */
function renderOwners(entrypoints) {
  const owner = (entry) => entry.featureCategories[0] ?? {};
  const cell = (value) => value ?? UNKNOWN;

  // Department, then stage, then group, then size with the biggest first.
  // Unknowns sort last at whichever level they are unknown. Stage sits between
  // department and group because it is the level the tables are split on, which
  // keeps each table contiguous and a department's stages adjacent.
  const sortKey = (entry) => {
    const { stage, group, department } = owner(entry);
    return [
      department ? 0 : 1,
      department ?? '',
      stage ?? '',
      group ? 0 : 1,
      group ?? '',
      -entry.reachableComponentCount,
      // Sort on the abbreviated name, so the column reads in the order shown.
      shortFileName(entry.fileNames[0]),
    ];
  };
  const rows = [...entrypoints].sort((a, b) => {
    const [keyA, keyB] = [sortKey(a), sortKey(b)];
    for (const [index, value] of keyA.entries()) {
      const order =
        typeof value === 'number' ? value - keyB[index] : value.localeCompare(keyB[index]);
      if (order !== 0) return order;
    }
    return 0;
  });

  // The stage is a heading rather than a column: it holds one value for a whole
  // table, and as a column its longest value would pad every row. The department
  // is derived from the stage, so it is constant too and joins it in the heading.
  const byStage = new Map();
  for (const entry of rows) {
    const stage = owner(entry).stage ?? null;
    if (!byStage.has(stage)) byStage.set(stage, []);
    byStage.get(stage).push(entry);
  }
  const headingFor = (stage, staged) => {
    if (!stage) return 'No owner';
    const { department } = owner(staged[0]);
    return department ? `${department}: ${stage}` : stage;
  };

  const code = (value) => (value ? `\`${value}\`` : '');
  const columns = [
    { header: 'group', of: (entry) => cell(owner(entry).group) },
    {
      header: 'fileName',
      // Both editions when EE shadows CE, so the wrapper never hides the page.
      // `<br>` is the only line break a Markdown table cell takes, and it is
      // plain ASCII, so terminal column widths are unaffected.
      of: (entry) => entry.fileNames.map((file) => code(shortFileName(file))).join('<br>'),
    },
    {
      header: 'size (components)',
      of: (entry) => `${sizeLabel(entry)} (${entry.reachableComponentCount})`,
    },
    { header: 'status', of: (entry) => `${SYMBOL[entry.status]} ${entry.status}` },
    { header: 'featureFlag', of: (entry) => code(flagLabel(entry)) },
  ];

  console.log();
  console.log("Ownership — inferred from the controller's feature_category");

  for (const [stage, staged] of byStage) {
    // Widths are per table, so a stage is only as wide as its own rows need.
    const widths = columns.map(({ header, of }) =>
      Math.max(header.length, ...staged.map((entry) => displayWidth(of(entry)))),
    );
    // Padded so the raw text stays readable in a terminal; renderers ignore it.
    const line = (values) =>
      `| ${values.map((value, index) => pad(value, widths[index])).join(' | ')} |`;

    console.log();
    // The count sits below the heading so the heading stays a stable anchor.
    console.log(`### ${headingFor(stage, staged)}`);
    console.log();
    console.log(`${staged.length} entrypoints`);
    console.log();
    console.log(line(columns.map(({ header }) => header)));
    console.log(`|${widths.map((width) => '-'.repeat(width + 2)).join('|')}|`);
    for (const entry of staged) console.log(line(columns.map(({ of }) => of(entry))));
  }

  const groups = new Set(entrypoints.map((entry) => owningGroup(entry)).filter(Boolean));
  const unowned = entrypoints.filter((entry) => !owningGroup(entry));
  console.log();
  console.log(
    `${entrypoints.length} entrypoints · ${entrypoints.length - unowned.length} across ` +
      `${groups.size} groups in ${byStage.size - (unowned.length ? 1 : 0)} stages · ` +
      `${unowned.length} with no owner`,
  );
}

// ───────────────────────────────────────────────────────────────────────
// Main
// ───────────────────────────────────────────────────────────────────────

const { entrypoints, edition, warnings, committedAt } = await collectEntrypoints();

if (JSON_OUTPUT) {
  console.log(JSON.stringify({ committedAt, edition, entrypoints }, null, 2));
} else {
  console.log(`Vue 3 page entrypoint migration — ${edition} build`);
  console.log(`Latest commit: ${committedAt ?? 'unknown'}`);
  if (TREE) renderTree(entrypoints);
  if (OWNERS) renderOwners(entrypoints);
  renderSummary(entrypoints);

  for (const warning of warnings) console.warn(`\nWarning: ${warning}`);
}
