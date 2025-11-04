/* eslint-disable import/no-default-export */
import path from 'node:path';
import { existsSync } from 'node:fs';
import localRules from 'eslint-plugin-local-rules';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';
// eslint-disable-next-line import/no-unresolved
import graphqlPlugin from '@graphql-eslint/eslint-plugin';
import * as todoLists from './.eslint_todo/index.mjs';

const { dirname } = import.meta;
const compat = new FlatCompat({
  baseDirectory: dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

const extendConfigs = [
  'plugin:@gitlab/default',
  'plugin:@gitlab/i18n',
  'plugin:no-jquery/slim',
  'plugin:no-jquery/deprecated-3.4',
  'plugin:no-unsanitized/recommended-legacy',
  './tooling/eslint-config/conditionally_ignore.js',
  'plugin:@gitlab/jest',
];

// Allowing JiHu to add rules on their side since the update from
// eslintrc.yml to eslint.config.mjs is not allowing subdirectory
// rewrite.
let jhConfigs = [];
if (existsSync(path.resolve(dirname, 'jh'))) {
  const pathToJhConfig = path.resolve(dirname, 'jh/eslint.config.js');
  // eslint-disable-next-line import/no-dynamic-require, no-unsanitized/method
  jhConfigs = (await import(pathToJhConfig)).default;
}

const jestConfig = {
  files: ['{,ee/}spec/frontend/**/*.js'],

  settings: {
    // We have to teach eslint-plugin-import what node modules we use
    // otherwise there is an error when it tries to resolve them
    'import/core-modules': ['events', 'fs', 'path'],
    'import/resolver': {
      jest: {
        jestConfigFile: 'jest.config.js',
      },
    },
  },

  rules: {
    '@gitlab/vtu-no-explicit-wrapper-destroy': 'error',
    'jest/expect-expect': [
      'off',
      {
        assertFunctionNames: ['expect*', 'assert*', 'testAction'],
      },
    ],
    '@gitlab/no-global-event-off': 'off',
    'import/no-unresolved': [
      'error',
      // The test fixtures and graphql schema are dynamically generated in CI
      // during the `frontend-fixtures` and `graphql-schema-dump` jobs.
      // They may not be present during linting.
      {
        ignore: ['^test_fixtures/', 'tmp/tests/graphql/gitlab_schema.graphql'],
      },
    ],
  },
};

/** An object to make it easier to reuse restricted imports */
const restrictedImportsPaths = {
  axios: {
    name: 'axios',
    message: 'Import axios from ~/lib/utils/axios_utils instead.',
  },
  mousetrap: {
    name: 'mousetrap',
    message: 'Import { Mousetrap } from ~/lib/mousetrap instead.',
  },
  sentry: {
    name: '@sentry/browser',
    message: 'Use "import * as Sentry from \'~/sentry/sentry_browser_wrapper\';" instead',
  },
  vuex: {
    name: 'vuex',
    message:
      'See our documentation on "Migrating from VueX" for tips on how to avoid adding new VueX stores.',
  },
};

const restrictedImportsPatterns = {
  gitlabUiDist: {
    group: ['@gitlab/ui/dist/*'],
    message:
      'Avoid importing from `@gitlab/ui/dist`. Our build uses aliases to force importing gitlab-ui from source, using `/dist` may have no effect.',
  },
};

export default [
  {
    ignores: [
      'app/assets/javascripts/locale/**/app.js',
      'builds/',
      'coverage/',
      'coverage-frontend/',
      'node_modules/',
      'public/',
      'tmp/',
      'vendor/',
      'sitespeed-result/',
      'fixtures/**/*.graphql',
      'storybook/public',
      'spec/fixtures/**/*.graphql',
      'ee/frontend_islands/',
    ],
  },
  ...compat.extends(...extendConfigs),
  ...compat.plugins('no-jquery'),
  {
    rules: {
      'no-unused-vars': [
        'error',
        {
          caughtErrors: 'none',
          ignoreRestSiblings: true,
        },
      ],
    },
  },
  {
    files: ['**/*.{js,vue}'],

    plugins: {
      'local-rules': localRules,
    },

    languageOptions: {
      globals: {
        __webpack_public_path__: true,
        gl: false,
        gon: false,
        localStorage: false,
        IS_EE: false,
      },
    },

    settings: {
      'import/resolver': {
        webpack: {
          config: './config/webpack.config.js',
        },
      },
    },

    rules: {
      'import/no-commonjs': 'error',
      'import/no-default-export': 'off',
      // Use dependency-cruiser to get an accurate analysis on circular dependencies
      // and for better performance
      'import/no-cycle': 'off',

      'no-underscore-dangle': [
        'error',
        {
          allow: ['__', '_links'],
        },
      ],

      'import/no-unresolved': [
        'error',
        {
          ignore: ['^(ee|jh)_component/', '^jh_else_ee/', '^fe_islands/'],
        },
      ],

      'lines-between-class-members': 'off',
      'no-jquery/no-animate-toggle': 'off',
      'no-jquery/no-event-shorthand': 'off',
      'no-jquery/no-serialize': 'error',
      'promise/always-return': 'off',
      'promise/no-callback-in-promise': 'off',
      '@gitlab/no-global-event-off': 'error',

      '@gitlab/vue-no-new-non-primitive-in-template': [
        'error',
        {
          allowNames: ['class(es)?$', '^style$', '^to$', '^$', '^variables$', 'attrs?$'],
        },
      ],

      '@gitlab/vue-no-undef-apollo-properties': 'error',
      '@gitlab/tailwind-no-interpolation': 'error',
      '@gitlab/vue-tailwind-no-interpolation': 'error',
      '@gitlab/tailwind-no-max-width-media-queries': 'error',
      '@gitlab/vue-tailwind-no-max-width-media-queries': 'error',

      'no-param-reassign': [
        'error',
        {
          props: true,
          ignorePropertyModificationsFor: ['acc', 'accumulator', 'el', 'element', 'state'],
          ignorePropertyModificationsForRegex: ['^draft'],
        },
      ],

      'import/order': [
        'error',
        {
          groups: ['builtin', 'external', 'internal', 'parent', 'sibling', 'index'],

          pathGroups: [
            {
              pattern: '~/**',
              group: 'internal',
            },
            {
              pattern: 'emojis/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,jh_,}empty_states/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,jh_,}icons/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,jh_,}images/**',
              group: 'internal',
            },
            {
              pattern: 'vendor/**',
              group: 'internal',
            },
            {
              pattern: 'shared_queries/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,}spec/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,jh_,}jest/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,jh_,any_}else_ce/**',
              group: 'internal',
            },
            {
              pattern: 'ee/**',
              group: 'internal',
            },
            {
              pattern: '{ee_,jh_,}component/**',
              group: 'internal',
            },
            {
              pattern: 'jh_else_ee/**',
              group: 'internal',
            },
            {
              pattern: 'jh/**',
              group: 'internal',
            },
            {
              pattern: '{test_,}helpers/**',
              group: 'internal',
            },
            {
              pattern: 'test_fixtures/**',
              group: 'internal',
            },
          ],

          alphabetize: {
            order: 'ignore',
          },
        },
      ],

      'no-restricted-syntax': [
        'error',
        {
          selector: "ImportSpecifier[imported.name='GlSkeletonLoading']",
          message: 'Migrate to GlSkeletonLoader, or import GlDeprecatedSkeletonLoading.',
        },
        {
          selector: "ImportSpecifier[imported.name='GlSafeHtmlDirective']",
          message: 'Use directive at ~/vue_shared/directives/safe_html.js instead.',
        },
        {
          selector: "ImportSpecifier[imported.name='GlBreakpointInstance']",
          message: 'GlBreakpointInstance only checks viewport breakpoints. You may want the breakpoints of a panel. Use PanelBreakpointInstance at ~/panel_breakpoint_instance instead (or add eslint-ignore here).',
        },
        {
          selector: 'Literal[value=/docs.gitlab.+\\u002Fee/]',
          message:
            'No hard coded url, use `DOCS_URL_IN_EE_DIR` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'TemplateElement[value.cooked=/docs.gitlab.+\\u002Fee/]',
          message:
            'No hard coded url, use `DOCS_URL_IN_EE_DIR` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'Literal[value=/(?=.*docs.gitlab.*)(?!.*\\u002Fee\\b.*)/]',
          message: 'No hard coded url, use `DOCS_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'TemplateElement[value.cooked=/(?=.*docs.gitlab.*)(?!.*\\u002Fee\\b.*)/]',
          message: 'No hard coded url, use `DOCS_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'Literal[value=/(?=.*about.gitlab.*)(?!.*\\u002Fblog\\b.*)/]',
          message: 'No hard coded url, use `PROMO_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'TemplateElement[value.cooked=/(?=.*about.gitlab.*)(?!.*\\u002Fblog\\b.*)/]',
          message: 'No hard coded url, use `PROMO_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector:
            'TemplateLiteral[expressions.0.name=DOCS_URL] > TemplateElement[value.cooked=/\\u002Fjh|\\u002Fee/]',
          message:
            '`/ee` or `/jh` path found in docs url, use `DOCS_URL_IN_EE_DIR` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector:
            "MemberExpression[object.type='ThisExpression'][property.name=/(\\$delete|\\$set)/]",
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
      ],

      'no-restricted-properties': [
        'error',
        {
          object: 'window',
          property: 'open',
          message:
            'Use `visitUrl` in `jh_else_ce/lib/utils/url_utility` to avoid cross-site leaks.',
        },
        {
          object: 'window',
          property: 'scrollTo',
          message:
            'Use `scrollTo` in `~/lib/utils/scroll_utils.js` to ensure scrolling inside your scrolling containers or panels.',
        },
        {
          object: 'window',
          property: 'scroll',
          message:
            'Use `scrollTo` in `~/lib/utils/scroll_utils.js` to ensure scrolling inside your scrolling containers or panels.',
        },
        {
          object: 'vm',
          property: '$delete',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
        {
          object: 'Vue',
          property: 'delete',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
        {
          object: 'vm',
          property: '$set',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
        {
          object: 'Vue',
          property: 'set',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
      ],

      'no-restricted-imports': [
        'error',
        {
          paths: [
            restrictedImportsPaths.axios,
            restrictedImportsPaths.mousetrap,
            restrictedImportsPaths.sentry,
            restrictedImportsPaths.vuex,
          ],

          patterns: [
            {
              group: ['react', 'react-dom/*'],
              message:
                'We do not allow usage of React in our codebase except for the graphql_explorer',
            },
            restrictedImportsPatterns.gitlabUiDist,
          ],
        },
      ],

      'unicorn/prefer-dom-node-dataset': ['error'],

      'no-unsanitized/method': [
        'error',
        {
          escape: {
            methods: ['sanitize'],
          },
        },
      ],

      'no-unsanitized/property': [
        'error',
        {
          escape: {
            methods: ['sanitize'],
          },
        },
      ],

      'unicorn/no-array-callback-reference': 'off',

      'vue/no-undef-components': [
        'error',
        {
          ignorePatterns: ['^router-link$', '^router-view$', '^gl-emoji$', 'fe-island-duo-next'],
        },
      ],

      'local-rules/require-valid-help-page-path': 'error',
      'local-rules/vue-require-valid-help-page-link-component': 'error',
    },
  },
  {
    files: ['**/*.vue'],
    rules: {
      'vue/no-unused-properties': [
        'error',
        {
          groups: ['props', 'data', 'computed', 'methods'],
        },
      ],
      'vue/require-name-property': 'error',
    },
  },
  {
    files: ['{,ee/,jh/}spec/frontend*/**/*'],

    rules: {
      '@gitlab/require-i18n-strings': 'off',
      '@gitlab/no-runtime-template-compiler': 'off',
      '@gitlab/tailwind-no-interpolation': 'off',
      '@gitlab/vue-tailwind-no-interpolation': 'off',
      '@gitlab/no-max-width-media-queries': 'off',
      '@gitlab/vue-tailwind-no-max-width-media-queries': 'off',
      'require-await': 'error',
      'import/no-dynamic-require': 'off',
      'no-import-assign': 'off',

      'no-restricted-syntax': [
        'error',
        {
          selector:
            'CallExpression[callee.object.name=/(wrapper|vm)/][callee.property.name="setData"]',
          message: 'Avoid using "setData" on VTU wrapper',
        },
        {
          selector:
            "MemberExpression[object.type!='ThisExpression'][property.type='Identifier'][property.name='$nextTick']",
          message:
            'Using $nextTick from a component instance is discouraged. Import nextTick directly from the Vue package.',
        },
        {
          selector: "Identifier[name='setImmediate']",
          message:
            'Prefer explicit waitForPromises (or equivalent), or jest.runAllTimers (or equivalent) to vague setImmediate calls.',
        },
        {
          selector: "ImportSpecifier[imported.name='GlSkeletonLoading']",
          message: 'Migrate to GlSkeletonLoader, or import GlDeprecatedSkeletonLoading.',
        },
        {
          selector:
            "CallExpression[arguments.length=1][arguments.0.type='Literal'] CallExpression[callee.property.name='toBe'] CallExpression[callee.property.name='attributes'][arguments.length=1][arguments.0.value='disabled']",
          message:
            'Avoid asserting disabled attribute exact value, because Vue.js 2 and Vue.js 3 renders it differently. Use toBeDefined / toBeUndefined instead',
        },
        {
          selector:
            "MemberExpression[object.object.name='Vue'][object.property.name='config'][property.name='errorHandler']",
          message:
            'Use setErrorHandler/resetVueErrorHandler from helpers/set_vue_error_handler.js instead.',
        },
        {
          selector: 'Literal[value=/docs.gitlab.+\\u002Fee/]',
          message:
            'No hard coded url, use `DOCS_URL_IN_EE_DIR` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'TemplateElement[value.cooked=/docs.gitlab.+\\u002Fee/]',
          message:
            'No hard coded url, use `DOCS_URL_IN_EE_DIR` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'Literal[value=/(?=.*docs.gitlab.*)(?!.*\\u002Fee\\b.*)/]',
          message: 'No hard coded url, use `DOCS_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'TemplateElement[value.cooked=/(?=.*docs.gitlab.*)(?!.*\\u002Fee\\b.*)/]',
          message: 'No hard coded url, use `DOCS_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'Literal[value=/(?=.*about.gitlab.*)(?!.*\\u002Fblog\\b.*)/]',
          message: 'No hard coded url, use `PROMO_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'TemplateElement[value.cooked=/(?=.*about.gitlab.*)(?!.*\\u002Fblog\\b.*)/]',
          message: 'No hard coded url, use `PROMO_URL` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector:
            'TemplateLiteral[expressions.0.name=DOCS_URL] > TemplateElement[value.cooked=/\\u002Fjh|\\u002Fee/]',
          message:
            '`/ee` or `/jh` path found in docs url, use `DOCS_URL_IN_EE_DIR` in `jh_else_ce/lib/utils/url_utility`',
        },
        {
          selector: 'CallExpression[callee.property.name=/(\\$delete|\\$set)/]',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
      ],

      'no-restricted-properties': [
        'error',
        {
          object: 'Vue',
          property: 'delete',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
        {
          object: 'Vue',
          property: 'set',
          message:
            "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
        },
      ],

      'no-unsanitized/method': 'off',
      'no-unsanitized/property': 'off',
      'local-rules/require-valid-help-page-path': 'off',
      'local-rules/vue-require-valid-help-page-link-component': 'off',

      'no-restricted-imports': [
        'error',
        {
          paths: [
            restrictedImportsPaths.axios,
            restrictedImportsPaths.mousetrap,
            restrictedImportsPaths.sentry,
            restrictedImportsPaths.vuex,
            {
              name: '~/locale',
              importNames: ['__', 's__'],
              message:
                'Do not externalize strings in specs: https://docs.gitlab.com/ee/development/i18n/externalization.html#test-files-jest',
            },
          ],

          patterns: [restrictedImportsPatterns.gitlabUiDist],
        },
      ],
    },
  },
  {
    files: [
      'config/**/*',
      'scripts/**/*',
      '**/*.config.js',
      '**/*.config.*.js',
      '**/jest_resolver.js',
      'eslint.config.mjs',
    ],

    rules: {
      '@gitlab/require-i18n-strings': 'off',
      'import/extensions': 'off',
      'import/no-extraneous-dependencies': 'off',
      'import/no-commonjs': 'off',
      'import/no-nodejs-modules': 'off',
      'filenames/match-regex': 'off',
      'no-console': 'off',
    },
  },
  {
    files: ['**/*.stories.js'],

    rules: {
      'filenames/match-regex': 'off',
      '@gitlab/require-i18n-strings': 'off',
      'import/no-unresolved': [
        'error',
        // The test fixtures are dynamically generated in CI during
        // the `frontend-fixtures` job. They may not be present during linting.
        {
          ignore: ['^test_fixtures/'],
        },
      ],
    },
  },
  {
    files: ['**/*.graphql'],

    languageOptions: {
      parserOptions: {
        parser: graphqlPlugin.parser,
        graphQLConfig: {
          documents: '{,ee/,jh/}app/**/*.graphql',
          schema: path.resolve(dirname, 'tmp/tests/graphql/gitlab_schema_apollo.graphql'),
        },
      },
    },

    plugins: {
      '@graphql-eslint': graphqlPlugin,
    },

    rules: {
      'filenames/match-regex': 'off',
      'spaced-comment': 'off',
      '@graphql-eslint/no-anonymous-operations': 'error',
      '@graphql-eslint/unique-operation-name': 'error',
      '@graphql-eslint/require-selections': 'error',
      '@graphql-eslint/no-unused-variables': 'error',
      '@graphql-eslint/no-unused-fragments': 'error',
      '@graphql-eslint/no-duplicate-fields': 'error',
    },
  },
  {
    files: [
      'app/assets/javascripts/projects/settings/branch_rules/queries/branch_rules_details.query.graphql',
      'app/assets/javascripts/projects/settings/repository/branch_rules/graphql/mutations/create_branch_rule.mutation.graphql',
      'app/assets/javascripts/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql',
      'ee/app/assets/javascripts/projects/settings/branch_rules/queries/branch_rules_details.query.graphql',
      'ee/app/assets/javascripts/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql',
    ],

    rules: {
      '@graphql-eslint/require-selections': 'off',
    },
  },
  {
    files: ['{,spec/}tooling/**/*'],

    rules: {
      'no-undef': 'off',
      'import/no-commonjs': 'off',
      'import/no-extraneous-dependencies': 'off',
      'no-restricted-syntax': 'off',
      '@gitlab/require-i18n-strings': 'off',
    },
  },

  // JIRA subscriptions config
  {
    files: ['app/assets/javascripts/jira_connect/subscriptions/**/*.{js,vue}'],

    languageOptions: {
      globals: {
        AP: 'readonly',
      },
    },

    rules: {
      '@gitlab/require-i18n-strings': 'off',
      '@gitlab/vue-require-i18n-strings': 'off',
    },
  },

  // Storybook config
  {
    files: ['storybook/**/*.{js,vue}'],

    rules: {
      '@gitlab/require-i18n-strings': 'off',
      'import/no-extraneous-dependencies': 'off',
      'import/no-commonjs': 'off',
      'import/no-nodejs-modules': 'off',
      'filenames/match-regex': 'off',
      'no-console': 'off',
      'import/no-unresolved': 'off',
    },
  },

  {
    files: ['storybook/config/test-runner.js'],

    rules: {
      'unicorn/filename-case': 'off',
    },
  },

  // Jest config
  jestConfig,

  // Integration tests config
  {
    files: ['{,ee/}spec/frontend_integration/**/*.js'],

    settings: {
      ...jestConfig.settings,
      'import/resolver': {
        jest: {
          jestConfigFile: 'jest.config.integration.js',
        },
      },
    },

    rules: {
      ...jestConfig.rules,
      'no-restricted-imports': ['error', 'fs'],
    },

    languageOptions: {
      globals: {
        mockServer: false,
      },
    },
  },

  /*
  contracts specs are a little different, as they are not "normal" jest specs.

  They are actually executing `jest` and e.g. do proper non-mocked calls with axios in order
  to check API contracts.

  They also do not directly execute library code, so some of our usual linting rules for app code
  like no-restricted-imports or i18n rules make no sense here and we can disable them.

  For reference: https://docs.gitlab.com/development/testing_guide/contract/
  */
  {
    files: ['{,ee/}spec/contracts/consumer/**/*.js'],

    settings: {
      'import/core-modules': ['@pact-foundation/pact', 'jest-pact'],
    },

    rules: {
      '@gitlab/require-i18n-strings': 'off',
      'no-restricted-imports': 'off',
    },
  },

  // k6 performance test configuration
  {
    files: ['qa/performance_test/k6_test/**/*.js'],

    languageOptions: {
      globals: {
        __ENV: 'readonly',
        __ITER: 'readonly',
        __VU: 'readonly',
        open: 'readonly',
      },
    },

    settings: {
      'import/ignore': ['k6', 'k6/', 'https://jslib.k6.io'],
    },

    rules: {
      // k6 modules are not resolvable by standard import resolver
      'import/no-unresolved': 'off',
      // k6 allows .js extensions in URLs
      'import/extensions': 'off',
      // k6 performance tests don't need internationalization
      '@gitlab/require-i18n-strings': 'off',
      // Console logging is expected in k6 tests
      'no-console': 'off',
      // Allow unnamed functions in k6 tests
      'func-names': 'off',
      // k6 globals are defined above
      'no-undef': 'off',
    },
  },
  ...jhConfigs,
  ...Object.values(todoLists),
];
