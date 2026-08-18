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

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const VUE3_MIGRATION_GLOB = `{,ee/,jh/}app/assets/javascripts/pages/**/${VUE3_MIGRATION_FILENAME}`;

/**
 * Extract the bundler entry name from a `vue3_migration.yml` path
 * relative to the repository root. The path is expected to contain
 * `app/assets/javascripts/pages/<entry-path>/vue3_migration.yml`.
 *
 * For example:
 *   `app/assets/javascripts/pages/projects/jobs/show/vue3_migration.yml`
 *   -> `pages.projects.jobs.show`
 *
 * @param {string} relFile - Path relative to ROOT_PATH.
 * @returns {string}
 */
function entryNameFromFile(relFile) {
  const match = relFile.match(/app\/assets\/javascripts\/pages\/(.+)\/[^/]+$/);
  if (!match) {
    throw new Error(`[vue3-migration] Unexpected file path: ${relFile}`);
  }
  return `pages.${match[1].split('/').join('.')}`;
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

  for (const relFile of files) {
    const absFile = path.join(ROOT_PATH, relFile);
    const entryName = entryNameFromFile(relFile);

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
