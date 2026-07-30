/**
 * File-format validation for `vue3_migration.yml` files.
 *
 * A page entry under `app/assets/javascripts/pages/**` (and the EE / JH
 * equivalents) opts into the Vue 3 migration system by adding a sibling
 * `vue3_migration.yml` file. Pages without such a file build only a
 * Vue 2 chunk and are served by Rails as Vue 2. The bundler reads these
 * files to decide whether to emit an additional `?vue3`-infected entry
 * sibling, and Rails reads them to decide which entrypoint to render.
 *
 * Status values:
 *
 *   rollout      Both the Vue 2 and Vue 3 bundles are built. Rails serves
 *                the Vue 3 bundle when the feature flag is enabled,
 *                otherwise the Vue 2 bundle.
 *                `feature_flag` is required.
 *
 *   migrated     Only the Vue 3 bundle is built. The original entry name
 *                resolves to the Vue 3 build. Use after the feature flag
 *                has been fully rolled out and removed.
 *                `feature_flag` must be absent.
 *
 * Lifecycle: file added with `rollout` -> moved to `migrated` once the
 * feature flag is retired -> file deleted once Vue 2 is no longer
 * needed for the page.
 */

const VUE3_MIGRATION_FILENAME = 'vue3_migration.yml';

const VUE3_MIGRATION_STATUS_ROLLOUT = 'rollout';
const VUE3_MIGRATION_STATUS_MIGRATED = 'migrated';

const ALL_STATUSES = [VUE3_MIGRATION_STATUS_ROLLOUT, VUE3_MIGRATION_STATUS_MIGRATED];
const ALLOWED_KEYS = Object.freeze(['status', 'feature_flag', 'group', 'migration_issue']);

/**
 * Validate a parsed `vue3_migration.yml` document.
 *
 * Returns an array of human-readable error strings. An empty array means
 * the document is valid.
 *
 * @param {unknown} doc - The parsed YAML document.
 * @returns {string[]}
 */
function validateVue3MigrationFile(doc) {
  const errors = [];

  if (doc === null || typeof doc !== 'object' || Array.isArray(doc)) {
    return ['must be a YAML map of values'];
  }

  const unknownKeys = Object.keys(doc).filter((k) => !ALLOWED_KEYS.includes(k));
  if (unknownKeys.length > 0) {
    errors.push(`unknown key(s): ${unknownKeys.join(', ')}`);
  }

  const { status, feature_flag: featureFlag } = doc;

  if (status === undefined || status === null) {
    errors.push('`status` is required');
  } else if (!ALL_STATUSES.includes(status)) {
    errors.push(
      `\`status\` must be one of: ${ALL_STATUSES.join(', ')} (got ${JSON.stringify(status)})`,
    );
  }

  if (status === VUE3_MIGRATION_STATUS_ROLLOUT) {
    if (typeof featureFlag !== 'string' || featureFlag.length === 0) {
      errors.push('`feature_flag` is required when status is `rollout`');
    }
  } else if (featureFlag !== undefined) {
    errors.push(`\`feature_flag\` must be absent when status is \`${status}\``);
  }

  return errors;
}

module.exports = {
  VUE3_MIGRATION_STATUS_ROLLOUT,
  VUE3_MIGRATION_STATUS_MIGRATED,
  VUE3_MIGRATION_FILENAME,
  validateVue3MigrationFile,
};
