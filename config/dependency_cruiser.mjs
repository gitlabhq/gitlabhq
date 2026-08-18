import chalk from 'chalk';
import noImportsFromEntrypointsTodo from '../.dependency_cruiser_todo/no-imports-from-entrypoints.mjs';
import noSharedLayerImportsFromFeaturesTodo from '../.dependency_cruiser_todo/no-shared-layer-imports-from-features.mjs';
import { ASSET_ROOT, ENTRYPOINTS, SHARED_LAYER, group } from './frontend_packages.mjs';

/**
 * The boundary rules below are ratchets: every violation that exists today is listed in
 * `.dependency_cruiser_todo/`, so the rules fail only on *new* ones. Set `REVEAL_DEPS_TODO=1` to
 * ignore those lists and see the current violation count.
 */
const revealDepsTodo = !['', '0', 'false', undefined].includes(process.env.REVEAL_DEPS_TODO);

/**
 * The todo lists hold plain file paths so they stay readable, but `pathNot` takes regular
 * expressions. Anchor each path and escape its metacharacters so an entry matches exactly the file
 * it names. Unanchored, `app/assets/javascripts/x.js` would also match
 * `ee/app/assets/javascripts/x.js` and silently exempt the other edition, and an unescaped `.`
 * would match any character.
 */
const escapeForRegExp = (value) => value.replaceAll(/[.*+?^${}()|[\]\\]/g, '\\$&');
const todo = (list) =>
  revealDepsTodo ? [] : list.files.map((file) => `^${escapeForRegExp(file)}$`);

let exclusionsListRegExp = ['^node_modules/.*'];
/**
 * NOTE: Do not use dependency-cruiser to generate exclusions and combine it with `--ignore-known`
 * flag, it'll fail; dependency-cruiser uses `webpack.config.js` to resolve aliases, and aliases
 * change at **runtime** based on whether we use FOSS (CE) or EE. So, even if the exclusions are
 * ignored in a normal run, they'll fail when the job is started with `as-if-foss`, which removes
 * the `ee/` directory and causes the aliases to resolves to CE imports.
 */

if (!process.env.DISABLE_EXCLUSIONS) {
  const msg = [
    `Known ${chalk.bold('no-circular')} violations are hidden. To see the full list, run the command ${chalk.bold.cyan('DISABLE_EXCLUSIONS=1 yarn deps:check:all')}.`,
    `If you have fixed existing circular dependencies or find false positives, you can add/remove them from the`,
    `exclusions list in the 'config/dependency_cruiser.mjs' file.`,
    '',
    `The package boundary rules keep their known violations in ${chalk.bold("'.dependency_cruiser_todo/'")} instead.`,
    `To see the full list for those, run ${chalk.bold.cyan('REVEAL_DEPS_TODO=1 yarn deps:check:all')}.`,
    '',
    chalk.italic(
      'If the above command fails because of memory issues, increase the memory by prepending it with the following',
    ),
    chalk.bold.cyan('NODE_OPTIONS="--max-old-space-size=4096"'),
  ];
  console.log(msg.join('\n'));

  exclusionsListRegExp = exclusionsListRegExp.concat([
    // Existing exclusions from eslint.config.mjs
    // https://gitlab.com/gitlab-org/gitlab/issues/28716
    '^(?:ee/)?app/assets/javascripts/filtered_search/.*.js$',
    // https://gitlab.com/gitlab-org/gitlab/issues/28719
    '^app/assets/javascripts/image_diff/.*.js$',

    // Other exclusions
    // Vulnerability Components
    '^ee/app/assets/javascripts/vulnerabilities/components/generic_report/.*.(?:vue|js)$',
    // Epic item
    'ee/app/assets/javascripts/roadmap/components/epic_item_container.vue',
    // Work items
    'app/assets/javascripts/work_items/components/(?:create_work_item_modal|work_item_detail).vue',
    'app/assets/javascripts/work_items/components/work_item_links/work_item_children_wrapper.vue',
    // Markdown
    'app/assets/javascripts/behaviors/markdown/render_gfm.js',
    // Merge request widget & tabs
    'app/assets/javascripts/vue_merge_request_widget/components/checks/constants.js',
    'app/assets/javascripts/merge_request_tabs.js',
    // Nested Group projects list
    'app/assets/javascripts/vue_shared/components/nested_groups_projects_list/nested_groups_projects_list_item.vue',
  ]);
}

/** @type {import('dependency-cruiser').IConfiguration} */
// eslint-disable-next-line import/no-default-export -- dependency-cruiser's config loader reads the default export
export default {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      comment: 'Circular dependencies are not allowed',
      from: { pathNot: '^(node_modules)' },
      to: {
        circular: true,
        // A dynamic import is lazy, so a cycle that passes through one is not an initialisation
        // cycle. This used to be achieved with `exclude: { dynamic: true }`, which dropped dynamic
        // edges for every rule and so hid them from the package boundary rules as well.
        viaOnly: { dependencyTypesNot: ['dynamic-import'] },
      },
    },
    {
      name: 'no-imports-from-entrypoints',
      severity: 'error',
      comment:
        'Entrypoints (see ENTRYPOINTS in config/frontend_packages.mjs) mirror the Rails route ' +
        'tree and the webpack entries: they may import anything, and nothing may import them. ' +
        'Move the shared code out of the entrypoint instead of importing from it.',
      from: {
        path: `${ASSET_ROOT}/`,
        pathNot: [`${ASSET_ROOT}/${group(ENTRYPOINTS)}/`, ...todo(noImportsFromEntrypointsTodo)],
      },
      to: { path: `${ASSET_ROOT}/${group(ENTRYPOINTS)}/` },
    },
    {
      name: 'no-shared-layer-imports-from-features',
      severity: 'error',
      comment:
        'Shared-layer packages (see SHARED_LAYER in config/frontend_packages.mjs) may be imported from ' +
        'anywhere, so they must not import feature code. If a shared module needs a value from a ' +
        'feature, move that value into the shared layer instead.',
      from: {
        path: `${ASSET_ROOT}/${group(SHARED_LAYER)}/`,
        pathNot: todo(noSharedLayerImportsFromFeaturesTodo),
      },
      // The trailing `/` keeps root-level modules such as `~/api.js` out of scope: they are not
      // in a package, so they cannot be feature code.
      to: {
        path: `${ASSET_ROOT}/[^/]+/`,
        pathNot: `${ASSET_ROOT}/${group(SHARED_LAYER)}/`,
      },
    },
  ],
  options: {
    /*
     Prevents dependency cruiser from following/analyzing dependencies in matched files.
     Files still appear in dependency graph if other files depend on them.
     More performant as it skips processing these files. Use for Vendor files, 3rd party code
     See https://github.com/sverweij/dependency-cruiser/blob/main/doc/options-reference.md#donotfollow-dont-cruise-modules-any-further
    */
    doNotFollow: {
      path: ['node_modules', ...exclusionsListRegExp],
    },
    /*
     Completely removes matched files from analysis
     Files won't appear in dependency graph at all
     Less performant as files are still initially processed to be filtered out from results
     See https://github.com/sverweij/dependency-cruiser/blob/main/doc/options-reference.md#exclude-exclude-dependencies-from-being-cruised
    */
    exclude: {
      path: [],
    },
    // NOTE: This option is required to resolve aliases from the webpack config
    webpackConfig: {
      fileName: './config/webpack.config.js',
    },
    // The cache key covers the files on disk, not the rule set, so a cached report can be replayed
    // for a different rule set. `REVEAL_DEPS_TODO` changes the effective rules without touching a
    // single file, so it has to bypass the cache or it reports whatever the previous run found.
    cache: revealDepsTodo
      ? false
      : {
          folder: './tmp/cache/depcruise-cache',
          // NOTE: if we want to store cache on CI, set the value to 'content'
          strategy: 'metadata',
          // With compression the cache is around 2MB
          // Without Compression, cache is 20 times larger
          compress: true,
        },
    // Optimize module resolution
    moduleSystems: ['es6', 'cjs', 'amd'],
    // default parser for js files
    parser: 'acorn',
    enhancedResolveOptions: {
      /*
       * NOTE: Running `depcruise info` command lists all the extensions that will be
       * analysed by default based on the parser and available compilers. Limiting them
       * to only the extensions we need improves performance.
       */
      extensions: ['.js', '.cjs', '.mjs', '.vue'],
    },

    /*
    skipAnalysisNotInRules will make dependency-cruiser execute
    analysis strictly necessary for checking the rule set only.

    See https://github.com/sverweij/dependency-cruiser/blob/main/doc/options-reference.md#skipanalysisnotinrules
    for details
   */
    skipAnalysisNotInRules: true,
  },
};
