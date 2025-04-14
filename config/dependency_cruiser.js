const chalk = require('chalk');

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
    `To see the full list of circular dependencies, run the command ${chalk.bold.cyan('DISABLE_EXCLUSIONS=1 yarn deps:check:all')}.`,
    `If you have fixed existing circular dependencies or find false positives, you can add/remove them from the`,
    `exclusions list in the 'config/dependency-cruiser.js' file.`,
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
module.exports = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      comment: 'Circular dependencies are not allowed',
      from: { pathNot: '^(node_modules)' },
      to: {
        circular: true,
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
      dynamic: true,
      path: [],
    },
    // NOTE: This option is required to resolve aliases from the webpack config
    webpackConfig: {
      fileName: './config/webpack.config.js',
    },
    cache: {
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
