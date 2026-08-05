/**
 * Frontend package taxonomy, used by the boundary rules in `config/dependency_cruiser.mjs`.
 *
 * Each top-level folder under `app/assets/javascripts` is treated as a package. A package spans
 * both editions: `app/assets/javascripts/ci/` and `ee/app/assets/javascripts/ci/` are the same
 * package, so EE code importing its CE counterpart is internal and allowed.
 *
 * See doc/development/fe_guide/package_boundaries.md for the rules and how to work with them.
 */

/**
 * Shared layer. These may be imported from anywhere, and in exchange they may only import each other
 * — never feature code. A shared-layer module that reaches into a feature drags that feature into
 * everything that uses it, which is what makes shared code impossible to reuse or extract.
 *
 * Enforced by the `no-shared-layer-imports-from-features` rule.
 */
export const SHARED_LAYER = [
  'api',
  'behaviors',
  'commons',
  'emoji',
  'graphql_shared',
  'helpers',
  'lib',
  'locale',
  'pinia',
  'sentry',
  'sortable',
  'tabs',
  'toggles',
  'tooltips',
  'tracking',
  'validators',
  'vue_shared',
  'vuex_shared',
];

/**
 * Consumer layer. `pages/` mirrors the Rails controller/action tree and `entrypoints/` holds
 * webpack entry files: both exist to wire everything else together, so they may import anything
 * and nothing may import them. Shared code belongs in a package, not in an entrypoint.
 *
 * Enforced by the `no-imports-from-entrypoints` rule.
 */
export const ENTRYPOINTS = ['pages', 'entrypoints'];

/**
 * Matches either edition's asset root. Anchored, for use as the prefix of a dependency-cruiser
 * `path` / `pathNot` regular expression.
 */
export const ASSET_ROOT = '^(?:ee/)?app/assets/javascripts';

/**
 * Builds a non-capturing regular expression alternation, e.g. `(?:pages|entrypoints)`.
 *
 * @param {string[]} names Package names.
 * @returns {string} A regular expression source fragment.
 */
export const group = (names) => `(?:${names.join('|')})`;
