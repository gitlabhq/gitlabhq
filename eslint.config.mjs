/* eslint-disable import/no-default-export */
import path from 'node:path';
import { existsSync } from 'node:fs';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';
import graphqlPlugin from '@graphql-eslint/eslint-plugin';
import noUnsanitizedPlugin from 'eslint-plugin-no-unsanitized';
import { conditionalIgnores } from './tooling/eslint-config/conditional_ignores.js';
import * as todoLists from './.eslint_todo/index.mjs';
import { eslintLocalRules } from './tooling/eslint-config/eslint-local-rules/index.mjs';

let { REVEAL_ESLINT_TODO } = process.env;
if (!REVEAL_ESLINT_TODO || REVEAL_ESLINT_TODO === 'false' || REVEAL_ESLINT_TODO === '0') {
  REVEAL_ESLINT_TODO = false;
}

const NO_HARDCODED_URLS_OPTIONS = {
  allowedKeys: ['path', 'redirect'],
  allowedFunctions: ['helpPagePath'],
  allowedInterpolationVariables: ['FORUM_URL', 'DOCS_URL', 'PROMO_URL', 'CONTRIBUTE_URL'],
  allowedPatterns: ['\\/api\\/:version'],
  disallowedObjectProperties: ['relative_url_root'],
};

// Rules disabled for non-production code (configs, tests, tools, stories, etc.)
const relaxedUrlAndI18nRules = {
  '@gitlab/require-i18n-strings': 'off',
  '@gitlab/no-hardcoded-urls': 'off',
  '@gitlab/vue-no-hardcoded-urls': 'off',
  'local-rules/no-web-url': 'off',
  'local-rules/vue-no-web-url': 'off',
};

const { dirname } = import.meta;
const compat = new FlatCompat({
  baseDirectory: dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

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
    // Catches the FOSS-only `import/no-duplicates` failure described in
    // gitlab-org/gitlab!230984: in EE, `jest/X` and `ee_else_ce_jest/X`
    // resolve to different files, but in FOSS the latter falls back to
    // the former, collapsing both imports onto the same path.
    'local-rules/no-mixed-jest-aliases': 'error',
  },
};

// ── Restricted Imports ──

const restrictedImportsPaths = [
  { name: 'axios', message: 'Import axios from ~/lib/utils/axios_utils instead.' },
  { name: 'mousetrap', message: 'Import { Mousetrap } from ~/lib/mousetrap instead.' },
  {
    name: '@sentry/browser',
    message: 'Use "import * as Sentry from \'~/sentry/sentry_browser_wrapper\';" instead',
  },
  {
    name: 'vuex',
    message:
      'See our documentation on "Migrating from VueX" for tips on how to avoid adding new VueX stores.',
  },
];

const restrictedImportsPatterns = [
  {
    group: ['@gitlab/ui/dist/*'],
    message:
      'Avoid importing from `@gitlab/ui/dist`. Our build uses aliases to force importing gitlab-ui from source, using `/dist` may have no effect.',
  },
  {
    group: ['react', 'react-dom/*'],
    message: 'We do not allow usage of React in our codebase except for the graphql_explorer',
  },
  {
    group: ['lodash', 'lodash/*'],
    message: 'Use lodash-es instead of lodash',
  },
];

const specRestrictedImportsPaths = [
  ...restrictedImportsPaths,
  {
    name: '~/locale',
    importNames: ['__', 's__'],
    message:
      'Do not externalize strings in specs: https://docs.gitlab.com/development/i18n/externalization.html#test-files-jest',
  },
];

const baseNoRestrictedSyntax = [
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
    message:
      'GlBreakpointInstance only checks viewport breakpoints. You may want the breakpoints of a panel. Use PanelBreakpointInstance at ~/panel_breakpoint_instance instead (or add eslint-ignore here).',
  },
  {
    selector: "MemberExpression[object.type='ThisExpression'][property.name=/(\\$delete|\\$set)/]",
    message:
      "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
  },
];

const specNoRestrictedSyntax = [
  ...baseNoRestrictedSyntax,
  {
    selector: 'CallExpression[callee.object.name=/(wrapper|vm)/][callee.property.name="setData"]',
    message: 'Avoid using "setData" on VTU wrapper',
  },
  {
    selector: "Identifier[name='setImmediate']",
    message:
      'Prefer explicit waitForPromises (or equivalent), or jest.runAllTimers (or equivalent) to vague setImmediate calls.',
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
    selector: 'CallExpression[callee.property.name=/(\\$delete|\\$set)/]',
    message:
      "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.",
  },
];

export default [
  // Global ignores
  {
    ignores: [
      ...conditionalIgnores,
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
      '{,ee/}app/assets/javascripts/lib/utils/path_helpers/*.js',
      'spec/frontend/scripts/infection_scanner/fixtures/**',

      // Dot-prefixed directories were implicitly ignored under legacy
      // eslintrc config (FlatCompat) but must be listed explicitly in flat config
      '.eslint_todo/**',
    ],
  },
  // Legacy plugin configs (via FlatCompat)
  ...compat.extends(
    'plugin:@gitlab/default',
    'plugin:@gitlab/i18n',
    'plugin:no-jquery/slim',
    'plugin:no-jquery/deprecated-3.4',
    'plugin:@gitlab/jest',
    'plugin:@gitlab/tailwind',
  ),
  ...compat.plugins('no-jquery'),
  // Native flat config plugins
  noUnsanitizedPlugin.configs.recommended,
  // Global rule overrides
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
    settings: {
      tailwindcss: {
        config: path.resolve(dirname, 'config/tailwind.config.js'),
      },
    },
  },
  // Main application code rules
  {
    files: ['**/*.{js,vue}'],

    plugins: {
      'local-rules': eslintLocalRules,
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
      // Import rules
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

      // jQuery rules
      'no-jquery/no-animate-toggle': 'off',
      'no-jquery/no-event-shorthand': 'off',
      'no-jquery/no-serialize': 'error',

      // Promise rules
      'promise/always-return': 'off',
      'promise/no-callback-in-promise': 'off',
      '@gitlab/no-global-event-off': 'error',

      // Vue rules
      '@gitlab/vue-no-new-non-primitive-in-template': [
        'error',
        {
          allowNames: ['class(es)?$', '^style$', '^to$', '^$', '^variables$', 'attrs?$'],
        },
      ],

      '@gitlab/vue-no-undef-apollo-properties': 'error',

      // URL rules
      '@gitlab/no-hardcoded-urls': ['error', NO_HARDCODED_URLS_OPTIONS],
      '@gitlab/vue-no-hardcoded-urls': [
        'error',
        {
          allowedVueComponents: ['help-page-link'],
          ...NO_HARDCODED_URLS_OPTIONS,
        },
      ],

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

      // Restricted syntax, properties, and imports
      'no-restricted-syntax': ['error', ...baseNoRestrictedSyntax],

      'no-restricted-properties': [
        'error',
        {
          object: 'window',
          property: 'open',
          message: 'Use `visitUrl` in `~/constants` to avoid cross-site leaks.',
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
          object: 'navigator',
          property: 'clipboard',
          message:
            'Use `copyToClipboard` in `~/lib/utils/copy_to_clipboard.js` to support copying in secure and non-secure environments.',
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
        {
          object: 'Vue',
          property: 'observable',
          message:
            'Use `observable()` from `~/lib/utils/observable` instead. Vue.observable is not shared across Vue 2/Vue 3 module boundaries.',
        },
      ],

      'no-restricted-imports': [
        'error',
        {
          paths: restrictedImportsPaths,
          patterns: [
            ...restrictedImportsPatterns,
            {
              group: ['ee/**/*'],
              message:
                'The `ee` import alias is only allowed in the `ee` directory. See https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-frontend.',
            },
          ],
        },
      ],

      'unicorn/prefer-dom-node-dataset': ['error'],

      // Sanitization rules
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

      // Local rules
      'local-rules/require-valid-help-page-path': 'error',
      'local-rules/vue-require-valid-help-page-link-component': 'error',
      'local-rules/vue-require-vue-constructor-name': 'error',
      'local-rules/no-orphaned-feature-flag-references': 'error',
      'local-rules/no-web-url': 'error',
      'local-rules/vue-no-web-url': 'error',
    },
  },
  // Overrides for EE files to be allowed to import from EE
  {
    files: ['ee/**/*.{js,vue}'],
    rules: {
      'no-restricted-imports': [
        'error',
        { paths: restrictedImportsPaths, patterns: restrictedImportsPatterns },
      ],
    },
  },
  // Vue file rules and Vue 3 compatibility
  {
    files: ['*.vue', '**/*.vue'],
    rules: {
      'vue/require-name-property': 'error',
      'vue/no-unused-properties': [
        'error',
        {
          groups: ['props', 'data', 'computed', 'methods', 'setup'],
        },
      ],
      'vue/no-undef-components': [
        'error',
        {
          ignorePatterns: ['^router-link$', '^router-view$', '^gl-emoji$', 'fe-island-duo-next'],
        },
      ],

      // Vue 3 events compatibility
      'vue/v-on-event-hyphenation': 'error',
      'vue/custom-event-name-casing': ['error', 'kebab-case'],
      'vue/require-explicit-emits': 'error',

      // Vue 3 deprecated features
      'vue/no-deprecated-data-object-declaration': 'error',
      'vue/no-deprecated-html-element-is': 'error',
      'vue/no-deprecated-inline-template': 'error',
      'vue/no-deprecated-props-default-this': 'error',
      'vue/no-deprecated-router-link-tag-prop': 'error',
      'vue/no-deprecated-slot-attribute': 'error',
      'vue/no-deprecated-v-bind-sync': 'error',
      'vue/no-deprecated-v-is': 'error',
      'vue/no-deprecated-v-on-native-modifier': 'error',
      'vue/no-deprecated-v-on-number-modifiers': 'error',
      'vue/no-deprecated-vue-config-keycodes': 'error',

      // Vue 3 components with render()
      'no-restricted-syntax': [
        'error',
        ...baseNoRestrictedSyntax,
        {
          selector: 'ExportDefaultDeclaration > ObjectExpression > Property[key.name="render"]',
          message:
            'Renderless components must be wrapped in normalizeRender(...) to ensure Vue.js 3 compatibility, e.g. export default normalizeRender({ ... }).',
        },
      ],
    },
  },
  // Spec files (unit tests)
  {
    files: ['{,ee/,jh/}spec/frontend*/**/*'],

    rules: {
      ...relaxedUrlAndI18nRules,
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
        ...specNoRestrictedSyntax,
        {
          selector:
            "MemberExpression[object.type!='ThisExpression'][property.type='Identifier'][property.name='$nextTick']",
          message:
            'Using $nextTick from a component instance is discouraged. Import nextTick directly from the Vue package.',
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
        {
          object: 'Vue',
          property: 'observable',
          message:
            'Use `observable()` from `~/lib/utils/observable` instead. Vue.observable is not shared across Vue 2/Vue 3 module boundaries.',
        },
      ],

      'no-unsanitized/method': 'off',
      'no-unsanitized/property': 'off',
      'local-rules/require-valid-help-page-path': 'off',
      'local-rules/vue-require-valid-help-page-link-component': 'off',

      'no-restricted-imports': [
        'error',
        {
          paths: specRestrictedImportsPaths,
          patterns: restrictedImportsPatterns,
        },
      ],
    },
  },
  // Storybook stories
  {
    files: ['**/*.stories.js'],

    rules: {
      ...relaxedUrlAndI18nRules,
      'filenames/match-regex': 'off',
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
  // GraphQL files
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
      'local-rules': eslintLocalRules,
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
      'local-rules/graphql-require-feature-category': 'error',
      'local-rules/graphql-require-valid-urgency': 'error',
    },
  },
  // GraphQL files that don't require selections (branch rules)
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
  // Config, scripts, and tooling files
  {
    files: [
      'config/**/*',
      'scripts/**/*',
      '**/*.config.js',
      '**/*.config.*.js',
      '{,spec/}tooling/**/*',
      'jest_resolver.js',
      'eslint.config.mjs',
      'doc/.markdownlint/**',
      'doc-locale/.markdownlint/**',
    ],

    rules: {
      ...relaxedUrlAndI18nRules,
      'import/extensions': 'off',
      'import/no-nodejs-modules': 'off',
      'filenames/match-regex': 'off',
      'no-console': 'off',
      'import/no-commonjs': 'off',
      'import/no-extraneous-dependencies': 'off',
      'import/no-unresolved': [
        'error',
        {
          ignore: [
            // False positive: eslint-plugin-import doesn't read `exports` field.
            // See https://github.com/import-js/eslint-plugin-import/issues/1810
            '^vite$',
            '^lightningcss$',
            '^vite-plugin-ruby$',
            '@graphql-eslint/eslint-plugin',
          ],
        },
      ],
    },
  },

  // Storybook config
  {
    files: ['storybook/**/*.{js,vue}'],

    rules: {
      ...relaxedUrlAndI18nRules,
      'import/no-extraneous-dependencies': 'off',
      'import/no-commonjs': 'off',
      'import/no-nodejs-modules': 'off',
      'filenames/match-regex': 'off',
      'no-console': 'off',
      'import/no-unresolved': 'off',
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

  // MSW integration tests
  {
    files: ['{,ee/}spec/frontend/msw_integration/**/*_spec.js'],
    languageOptions: {
      globals: {
        waitForElement: 'readonly',
        getText: 'readonly',
        findByTestId: 'readonly',
        findInDrawer: 'readonly',
        findButtonByText: 'readonly',
        findByGraphQLId: 'readonly',
        setInputValue: 'readonly',
        waitAndSetValue: 'readonly',
        waitAndClick: 'readonly',
        waitForElementToBeNull: 'readonly',
        waitForAssertion: 'readonly',
        createPortalElement: 'readonly',
        assignRouter: 'readonly',
        fullMount: 'readonly',
        capturedRequests: 'readonly',
        resetCapturedRequests: 'readonly',
        captureRequest: 'readonly',
      },
    },

    rules: {
      ...jestConfig.rules,
      '@gitlab/require-i18n-strings': 'off',
      '@gitlab/no-hardcoded-urls': 'off',
      'jest/no-standalone-expect': 'off',
      'no-restricted-imports': [
        'error',
        {
          paths: [
            ...specRestrictedImportsPaths,
            {
              name: 'helpers/wait_for_promises',
              message: 'Use waitFor from @testing-library/dom instead.',
            },
            {
              name: 'helpers/vue_test_utils_helper',
              importNames: ['mountExtended', 'shallowMountExtended'],
              message:
                'Use mount from @vue/test-utils instead. After mounting, use native DOM APIs for interactions and assertions.',
            },
            {
              name: '@vue/test-utils',
              importNames: ['createWrapper'],
              message:
                'Do not wrap DOM elements in VTU wrappers. Use native DOM APIs (querySelector, click, getAttribute) instead.',
            },
          ],
          patterns: [
            ...restrictedImportsPatterns,
            {
              group: ['vue'],
              importNames: ['nextTick'],
              message: 'Use waitFor from @testing-library/dom instead of nextTick.',
            },
          ],
        },
      ],
      'no-restricted-syntax': [
        'error',
        ...specNoRestrictedSyntax,
        {
          selector: 'CallExpression[callee.object.name=/[Rr]outer/][callee.property.name="push"]',
          message:
            'Do not use router.push. Use the UI to trigger actions which in turn trigger route changes to simulate user behaviours.',
        },
        {
          selector:
            'CallExpression[callee.object.property.name=/[Rr]outer/][callee.property.name="push"]',
          message:
            'Do not use router.push. Use the UI to trigger actions which in turn trigger route changes to simulate user behaviours.',
        },
        {
          selector: 'MemberExpression[property.name="nextTick"]',
          message: 'Use waitFor from @testing-library/dom instead of nextTick.',
        },
        {
          selector: 'MemberExpression[property.name="$nextTick"]',
          message: 'Use waitFor from @testing-library/dom instead of $nextTick.',
        },
        {
          selector: 'MemberExpression[property.name="__vue__"]',
          message: 'Do not access Vue internals on DOM elements. Use native DOM APIs instead.',
        },
        {
          selector: 'CallExpression[callee.property.name="findComponent"]',
          message:
            'Do not use findComponent. Use querySelector with a data-testid or role attribute instead.',
        },
        {
          selector:
            'CallExpression[callee.object.property.name="vm"][callee.property.name="$emit"]',
          message:
            'Do not emit events on component instances. Trigger the user interaction that causes the event instead.',
        },
      ],
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
      ...relaxedUrlAndI18nRules,
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
      ...relaxedUrlAndI18nRules,
      // Console logging is expected in k6 tests
      'no-console': 'off',
      // Allow unnamed functions in k6 tests
      'func-names': 'off',
      // k6 globals are defined above
      'no-undef': 'off',
    },
  },

  // web worker rules
  {
    files: ['{,ee/}app/assets/javascripts/**/*_worker.js'],

    languageOptions: {
      globals: {
        self: 'readonly',
      },
    },

    rules: {
      'no-restricted-globals': 'off',
    },
  },

  ...jhConfigs,
  ...Object.values(REVEAL_ESLINT_TODO ? {} : todoLists),
];
