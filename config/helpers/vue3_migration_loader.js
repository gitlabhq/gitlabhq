const path = require('path');
const fs = require('fs');
const glob = require('glob');
const yaml = require('js-yaml');
const {
  VUE3_MIGRATION_FILENAME,
  VUE3_MIGRATION_STATUS_ROLLOUT,
  VUE3_MIGRATION_STATUS_MIGRATED,
  validateVue3MigrationFile,
} = require('./vue3_migration_file_validation');
const { baseEntryPoints, pageEntryName } = require('./entry_points');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const JS_ROOTS = [
  'app/assets/javascripts',
  'ee/app/assets/javascripts',
  'jh/app/assets/javascripts',
];

// A migration file sits beside the entry module it describes, wherever that is.
const VUE3_MIGRATION_GLOB = `{,ee/,jh/}app/assets/javascripts/**/*${VUE3_MIGRATION_FILENAME}`;

// `vue3_migration.yml` describes `index.js`, `<name>.vue3_migration.yml` describes `<name>.js`.
const MIGRATION_FILE_RE = new RegExp(
  `^(?:(.+)\\.)?${VUE3_MIGRATION_FILENAME.replace(/\./g, '\\.')}$`,
);

// `default` (`./main`) is prepended to every page entry rather than emitted as a
// bundle of its own, so there is no asset for Rails to swap.
const MAIN_MODULE = path.posix.join(JS_ROOTS[0], `${baseEntryPoints.default[0]}.js`);

// Repo-relative entry module path -> bundler entry name, for every entry the bundler knows.
function entryModules() {
  const index = {};

  for (const [name, spec] of Object.entries(baseEntryPoints)) {
    if (typeof spec !== 'string') continue;
    index[path.posix.join(JS_ROOTS[0], spec)] = name;
  }

  for (const root of JS_ROOTS) {
    for (const rel of glob.sync('pages/**/index.js', { cwd: path.join(ROOT_PATH, root) })) {
      index[path.posix.join(root, rel)] = pageEntryName(rel);
    }
  }

  return index;
}

/**
 * The entry module a migration file describes, relative to the repository root.
 *
 *   `app/assets/javascripts/pages/projects/jobs/show/vue3_migration.yml`
 *   -> `app/assets/javascripts/pages/projects/jobs/show/index.js`
 *
 *   `app/assets/javascripts/entrypoints/super_sidebar.vue3_migration.yml`
 *   -> `app/assets/javascripts/entrypoints/super_sidebar.js`
 *
 * @param {string} relFile - Path relative to ROOT_PATH.
 * @returns {string}
 */
function entryModuleFor(relFile) {
  const match = path.posix.basename(relFile).match(MIGRATION_FILE_RE);
  if (!match) {
    throw new Error(`[vue3-migration] Unexpected file name: ${relFile}`);
  }

  return path.posix.join(path.posix.dirname(relFile), `${match[1] ?? 'index'}.js`);
}

/**
 * The bundler entry name a migration file describes, looked up in `entryModules`.
 *
 * @param {string} relFile - Path relative to ROOT_PATH.
 * @param {Record<string, string>} index - From `entryModules()`.
 * @returns {string}
 */
function entryNameFromFile(relFile, index) {
  const moduleFile = entryModuleFor(relFile);

  if (moduleFile === MAIN_MODULE) {
    throw new Error(
      `[vue3-migration] ${relFile} cannot be migrated this way. \`main\` is prepended to every ` +
        `page entry instead of being emitted as its own bundle, so there is no asset to swap. ` +
        `Use the \`?vue3\` import documented as Option 2 in doc/development/fe_guide/vue3_migration.md.`,
    );
  }

  const entryName = index[moduleFile];
  if (!entryName) {
    throw new Error(
      `[vue3-migration] ${relFile} describes ${moduleFile}, which is not a bundler entry. ` +
        `Entries are the values of config/helpers/entry_points.js and every pages/**/index.js.`,
    );
  }

  return entryName;
}

/**
 * Canonical JSON serialization with sorted top-level keys, used to
 * compare two parsed YAML documents for deep equality regardless of the
 * order in which their keys appear in the source file.
 *
 * @param {object} doc
 * @returns {string}
 */
function canonicalize(doc) {
  return JSON.stringify(doc, Object.keys(doc).sort());
}

/**
 * Load and validate every `vue3_migration.yml` file in the project.
 *
 * When the same entry name is declared in more than one page root
 * (e.g. CE and EE both have `pages/projects/jobs/show/index.js`), the
 * corresponding YAML files must be identical. This avoids subtle drift
 * between FOSS and EE builds where the same page would otherwise
 * resolve to different migration states.
 *
 * Throws on the first invalid file or first shadow inconsistency with
 * a contextual error message.
 *
 * @returns {Record<string, { status: string, feature_flag?: string }>}
 *   Object keyed by entry name (e.g. `pages.projects.jobs.show`).
 */
function loadVue3Migrations() {
  // Per entry name, collect every YAML that declares it so we can
  // cross-check once everything is loaded.
  const collected = {};

  const files = glob.sync(VUE3_MIGRATION_GLOB, { cwd: ROOT_PATH });
  const index = entryModules();

  for (const relFile of files) {
    const absFile = path.join(ROOT_PATH, relFile);
    const entryName = entryNameFromFile(relFile, index);

    let doc;
    try {
      doc = yaml.safeLoad(fs.readFileSync(absFile, 'utf-8'));
    } catch (err) {
      throw new Error(`[vue3-migration] Failed to parse ${absFile}: ${err.message}`);
    }

    const errors = validateVue3MigrationFile(doc);
    if (errors.length > 0) {
      throw new Error(`[vue3-migration] Invalid ${absFile}:\n  - ${errors.join('\n  - ')}`);
    }

    collected[entryName] ||= [];
    collected[entryName].push({ absFile, doc });
  }

  // Enforce shadow consistency and project the final migration map.
  const migrations = {};

  for (const [entryName, occurrences] of Object.entries(collected)) {
    if (occurrences.length > 1) {
      const [first, ...rest] = occurrences;
      const firstSerialized = canonicalize(first.doc);

      for (const other of rest) {
        const otherSerialized = canonicalize(other.doc);
        if (otherSerialized !== firstSerialized) {
          throw new Error(
            `[vue3-migration] Shadowed entry "${entryName}" has divergent metadata:\n` +
              `  ${first.absFile}: ${firstSerialized}\n` +
              `  ${other.absFile}: ${otherSerialized}\n` +
              `Shadowed YAMLs must be identical across CE/EE/JH for the same page.`,
          );
        }
      }
    }

    const { doc } = occurrences[0];
    migrations[entryName] = {
      status: doc.status,
      ...(doc.feature_flag ? { feature_flag: doc.feature_flag } : {}),
    };
  }

  return migrations;
}

/**
 * Project the migration map down to the entries Rails needs at runtime.
 *
 * Only `rollout` entries require runtime metadata: Rails switches between
 * the `<entry>` and `<entry>.vue3` bundles based on the feature flag.
 * `migrated` pages build the Vue 3 bundle under the original entry name,
 * so Rails serves them with no lookup at all.
 *
 * @param {Record<string, { status: string, feature_flag?: string }>} migrations
 * @returns {Record<string, { feature_flag: string }>} Sorted by entry name.
 */
function rolloutEntries(migrations) {
  return Object.fromEntries(
    Object.entries(migrations)
      .filter(([, migration]) => migration.status === VUE3_MIGRATION_STATUS_ROLLOUT)
      .map(([entryName, migration]) => [entryName, { feature_flag: migration.feature_flag }])
      .sort(([a], [b]) => a.localeCompare(b)),
  );
}

/**
 * Append the `?vue3` query to a module path. No-op if it already has one.
 *
 * @param {string} modulePath
 * @returns {string}
 */
function appendVue3Query(modulePath) {
  if (modulePath.includes('?vue3') || /[?&]vue3(&|$)/.test(modulePath)) {
    return modulePath;
  }
  return modulePath.includes('?') ? `${modulePath}&vue3` : `${modulePath}?vue3`;
}

module.exports = {
  loadVue3Migrations,
  rolloutEntries,
  appendVue3Query,
  VUE3_MIGRATION_STATUS_ROLLOUT,
  VUE3_MIGRATION_STATUS_MIGRATED,
};
