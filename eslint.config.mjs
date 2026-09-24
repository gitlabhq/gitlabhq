/* eslint-disable import/no-default-export */
import path from 'node:path';
import { existsSync } from 'node:fs';
import gitlabPlugin from '@gitlab/eslint-plugin';
import graphqlPlugin from '@graphql-eslint/eslint-plugin';
import noUnsanitizedPlugin from 'eslint-plugin-no-unsanitized';
import noJQueryPlugin from 'eslint-plugin-no-jquery';
import globals from 'globals';
import confusingBrowserGlobals from 'confusing-browser-globals';
import { conditionalIgnores } from './tooling/eslint-config/conditional_ignores.js';
import * as todoLists from './.eslint_todo/index.mjs';
import { eslintLocalRules } from './tooling/eslint-config/eslint-local-rules/index.mjs';

// Follows the legacy `extends` chain, since no-jquery doesn't ship flat configs.
function resolveNoJQueryConfigRules(configName) {
  const config = noJQueryPlugin.configs[configName];
  if (!config) {
    throw new Error(
      `
Can't find no-jquery config "${configName}".
Available configs are:${Object.keys(noJQueryPlugin.configs)
        .map((name) => `\n- ${name}`)
        .join('')}`,
    );
  }

  const parentRules = [config.extends ?? []]
    .flat()
    .map((parent) => resolveNoJQueryConfigRules(parent.replace('plugin:no-jquery/', '')));

  return Object.assign({}, ...parentRules, config.rules);
}

function noJQueryDeprecatedUntilVersion(version) {
  return { rules: resolveNoJQueryConfigRules(`deprecated-${version}`) };
}

let { REVEAL_ESLINT_TODO } = process.env;
if (!REVEAL_ESLINT_TODO || REVEAL_ESLINT_TODO === 'false' || REVEAL_ESLINT_TODO === '0') {
  REVEAL_ESLINT_TODO = false;
}

const NO_HARDCODED_URLS_OPTIONS = {
  allowedKeys: ['path', 'redirect'],
  allowedFunctions: ['helpPagePath', 'dispatch', 'commit'],
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
    'vue/require-name-property': 'off',
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
    // Specs must not rely on the VTU v1 "find upgrade" (string-selector
    // find() returning component wrappers), which the vue-test-utils-compat
    // shim emulates in the Vue 3 jest lane via
    // WRAPPER_FIND_BY_CSS_SELECTOR_RETURNS_COMPONENTS. Use the explicit
    // component finders (findComponent/findComponentByTestId) instead.
    // Batch-fix with `scripts/frontend/codemods/vue3_find_component_upgrade.mjs`.
    'local-rules/vue3-find-component-upgrade': 'error',
  },
};

// ── Restricted Globals ──

const restrictedGlobals = [
  ...confusingBrowserGlobals,
  {
    name: 'isFinite',
    message:
      'Use Number.isFinite instead https://github.com/airbnb/javascript#standard-library--isfinite',
  },
  {
    name: 'isNaN',
    message:
      'Use Number.isNaN instead https://github.com/airbnb/javascript#standard-library--isnan',
  },
  {
    name: 'escape',
    message: 'The global `escape` function is deprecated, use `encodeURI` instead.',
  },
  {
    name: 'unescape',
    message: 'The global `unescape` function is deprecated, use `decodeURI` instead.',
  },
  {
    name: 'structuredClone',
    message:
      'Use `cloneDeep` from lodash-es instead. `structuredClone` throws `DataCloneError` on a Proxy, ' +
      'and Vue 3 reactive state is a Proxy.',
  },
];

// ── Restricted Imports ──

const restrictedImportsPaths = [
  { name: 'axios', message: 'Import axios from ~/lib/utils/axios_utils instead.' },
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
  {
    // Leading slash anchors the match; without it `~/lib/mousetrap` is caught too.
    group: ['/mousetrap', '/mousetrap/*'],
    message:
      'Import { Mousetrap } from ~/lib/mousetrap instead, and add any plugin behaviour there.',
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

const VUE_SET_DELETE_MESSAGE =
  "Vue 2's set/delete methods are not available in Vue 3. Create/assign new objects with the desired properties instead.";

// Restricted `Vue.*` statics, shared by the app and spec blocks.
const vueGlobalRestrictedProperties = [
  { object: 'Vue', property: 'delete', message: VUE_SET_DELETE_MESSAGE },
  { object: 'Vue', property: 'set', message: VUE_SET_DELETE_MESSAGE },
  {
    object: 'Vue',
    property: 'observable',
    message:
      'Use `observable()` from `~/lib/utils/observable` instead. Vue.observable is not shared across Vue 2/Vue 3 module boundaries.',
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
    message: VUE_SET_DELETE_MESSAGE,
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
      // eslintrc config (FlatCompat) but must be listed explicitly in flat config.
      // Both of these hold generated todo lists, so they are not linted.
      '.eslint_todo/**',
      '.dependency_cruiser_todo/**',

      // Shared agent skills are documentation assets (including example
      // .graphql queries), not application code, so they are not linted.
      '.claude/skills/**',
    ],
  },
  ...gitlabPlugin.configs.default,
  ...gitlabPlugin.configs.i18n,
  ...gitlabPlugin.configs.jest,
  ...gitlabPlugin.configs.tailwind,
  noJQueryPlugin.configs.slim,
  noJQueryDeprecatedUntilVersion('3.4'),
  // Native flat config plugins
  noUnsanitizedPlugin.configs.recommended,
  // Registered here with no `files` key so it applies to every linted file:
  // flat config merges the `plugins` of all matching objects before resolving
  // rule names, so rules need not be co-located with their plugin.
  // https://eslint.org/docs/latest/use/configure/configuration-files
  {
    plugins: {
      'local-rules': eslintLocalRules,
      'no-jquery': noJQueryPlugin,
    },

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
      // Dependency rules are enfoced by `config/dependency_cruiser.mjs`
      // It is more accurate and faster than the ESLint rule.
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
      'vue/no-deprecated-delete-set': 'error',
      // Covers new Vue(), Vue.extend(), defineComponent() and createApp() too.
      // The name is stamped on Vue 3 app roots as data-gitlab-vue3-app.
      'vue/require-name-property': 'error',
      // Prefers $scopedSlots, which vue/no-deprecated-dollar-scopedslots-api
      // forbids. Removed upstream in gitlab-org/frontend/eslint-plugin!175.
      '@gitlab/vue-prefer-dollar-scopedslots': 'off',

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
      'no-restricted-syntax': [
        'error',
        ...baseNoRestrictedSyntax,
        {
          // vue/no-deprecated-delete-set only sees component bodies, so a
          // .js mixin object needs this guard. The .vue block drops it.
          selector:
            "MemberExpression[object.type='ThisExpression'][property.name=/(\\$delete|\\$set)/]",
          message: VUE_SET_DELETE_MESSAGE,
        },
      ],

      'no-restricted-globals': ['error', ...restrictedGlobals],

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
        ...vueGlobalRestrictedProperties,
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
      'local-rules/no-orphaned-feature-flag-references': 'error',
      'local-rules/no-root-toast': 'error',
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
  // Page entrypoints must be top-level execution scripts and must not export anything.
  // See `scripts/frontend/find_pages_without_top_level_execution.mjs`.
  {
    files: ['{,ee/,jh/}app/assets/javascripts/pages/**/index.js'],
    rules: {
      'local-rules/page-entrypoint-must-execute': 'error',
    },
  },
  // Vue file rules and Vue 3 compatibility
  {
    files: ['*.vue', '**/*.vue'],
    rules: {
      // eslint-plugin-vue v10 ships this at `warn`; raised to `error` so the
      // `.eslint_todo` exemption list is the only thing keeping it green.
      'vue/no-required-prop-with-default': 'error',
      'vue/no-unused-properties': [
        'error',
        {
          groups: ['props', 'data', 'computed', 'methods', 'setup', 'inject'],
        },
      ],
      'local-rules/vue-no-router-view-listeners-or-slots': 'error',
      'vue/no-undef-components': [
        'error',
        {
          ignorePatterns: ['^router-link$', '^router-view$', '^gl-emoji$', 'fe-island-duo-next'],
        },
      ],
      // Under Vue 3, apps share no global directive registrations, so an
      // unregistered `v-x` silently renders nothing.
      'vue/no-undef-directives': 'error',

      // Vue 3 essentials that the Vue 2 preset leaves off
      'vue/no-lifecycle-after-await': 'error',
      'vue/no-watch-after-await': 'error',
      'vue/no-expose-after-await': 'error',
      'vue/prefer-import-from-vue': 'error',
      'vue/require-slots-as-functions': 'error',
      'vue/require-toggle-inside-transition': 'error',

      // Vue 3 events compatibility
      'vue/v-on-event-hyphenation': 'error',
      // `update:` events must match their prop name exactly for `.sync`/v-model
      // to bind, so they cannot be kebab-cased. eslint-plugin-vue v9 exempted
      // them implicitly; v10 checks each colon-separated segment instead.
      'vue/custom-event-name-casing': ['error', 'kebab-case', { ignores: ['/^update:/'] }],
      'vue/require-explicit-emits': 'error',

      // Vue 3 deprecated features that @gitlab/eslint-plugin does not enable.
      // Left off on purpose while the code still uses the Vue 2 syntax:
      // no-deprecated-destroyed-lifecycle and no-deprecated-model-definition.
      // $listeners reads are converted to the dual-runtime glListeners()
      // mixin (lib/utils/vue3compat/gl_listeners_mixin.js): Vue 3 removed
      // $listeners, and on Vue 2 $attrs never contains listeners, so
      // neither spelling works alone on both runtimes.
      // Batch-fix with `scripts/frontend/codemods/vue3_gl_listeners.mjs`.
      'vue/no-deprecated-dollar-listeners-api': 'error',
      'vue/no-deprecated-dollar-scopedslots-api': 'error',
      'vue/no-deprecated-router-link-tag-prop': 'error',
      'vue/no-deprecated-v-bind-sync': 'error',
      'vue/no-deprecated-v-is': 'error',
      'vue/no-deprecated-v-on-native-modifier': 'error',

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

      // A mixin registration and a usage of what it supplies must appear in
      // the same file, both ways. Mixins are identified by import, so local
      // aliases (glFeatureFlagMixin, TimeagoMixin) resolve to the same entry.
      // `reportUnused: false` marks entries whose existing unused
      // registrations are still being removed; the missing half stays on.
      'local-rules/vue-mixin-pairing': [
        'error',
        {
          mixins: [
            { source: '@gitlab/ui', imported: 'GlToastMixin', members: ['$toast'] },
            {
              source: '~/lib/utils/vue3compat/gl_slots_mixin',
              imported: 'glSlotsMixin',
              members: ['glSlots'],
            },
            {
              source: '~/lib/utils/vue3compat/gl_listeners_mixin',
              imported: 'glListenersMixin',
              members: ['glListeners', 'glListener'],
            },
            {
              source: '~/vue_shared/mixins/gl_feature_flags_mixin',
              imported: 'default',
              localName: 'glFeatureFlagsMixin',
              factory: true,
              members: ['glFeatures'],
            },
            {
              source: '~/vue_shared/mixins/gl_abilities_mixin',
              imported: 'default',
              localName: 'glAbilitiesMixin',
              factory: true,
              members: ['glAbilities'],
              reportUnused: false,
            },
            {
              source: '~/vue_shared/mixins/gl_licensed_features_mixin',
              imported: 'default',
              localName: 'glLicensedFeaturesMixin',
              factory: true,
              members: ['glLicensedFeatures'],
            },
            {
              source: '~/vue_shared/mixins/timeago',
              imported: 'default',
              localName: 'timeagoMixin',
              members: ['timeFormatted', 'tooltipTitle'],
              reportUnused: false,
            },
            {
              source: '~/tracking',
              imported: 'InternalEvents',
              factory: 'mixin',
              members: ['trackEvent'],
              reportUnused: false,
            },
            {
              source: '~/tracking/internal_events',
              imported: 'default',
              localName: 'InternalEvents',
              factory: 'mixin',
              members: ['trackEvent'],
              reportUnused: false,
            },
            {
              source: '~/tracking',
              imported: 'default',
              localName: 'Tracking',
              factory: 'mixin',
              members: ['track', 'trackingCategory', 'trackingOptions'],
              reportUnused: false,
            },
          ],
        },
      ],
    },
  },
  // App code only: the deliberate slot-forwarding fixtures in
  // spec/frontend/vue3migration and storybook helpers stay unguarded.
  {
    files: ['{,ee/,jh/}app/assets/javascripts/**/*.vue'],
    rules: {
      'local-rules/vue3-no-unconditional-slot-forwarding': 'error',
    },
  },
  {
    files: [
      'app/assets/javascripts/access_tokens/components/token.vue',
      'ee/app/assets/javascripts/groups/settings/components/comma_separated_list_token_selector.vue',
      'ee/app/assets/javascripts/members/components/action_dropdowns/ldap_override_dropdown_item.vue',
    ],
    rules: {
      'local-rules/vue3-no-unconditional-slot-forwarding': 'off',
    },
  },
  {
    files: [
      'app/assets/javascripts/packages_and_registries/container_registry/explorer/components/list_page/registry_header.vue',
      'app/assets/javascripts/packages_and_registries/harbor_registry/components/list/harbor_list_header.vue',
    ],
    rules: {
      'local-rules/vue3-no-unconditional-slot-forwarding': 'off',
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
      'import/no-extraneous-dependencies': 'off',
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

      'no-restricted-properties': ['error', ...vueGlobalRestrictedProperties],

      'no-unsanitized/method': 'off',
      'no-unsanitized/property': 'off',
      'local-rules/require-valid-help-page-path': 'off',
      'local-rules/vue-require-valid-help-page-link-component': 'off',
      'local-rules/no-apollo-mock': 'error',

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

  // Frontend integration tests (EE-only)
  {
    files: ['ee/spec/frontend/integration/**/*_spec.js'],
    languageOptions: {
      globals: {
        waitForElement: 'readonly',
        getText: 'readonly',
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
        screen: 'readonly',
        within: 'readonly',
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
              message: 'Use waitFor from @testing-library/vue instead.',
            },
            {
              name: 'helpers/vue_test_utils_helper',
              importNames: ['mountExtended', 'shallowMountExtended'],
              message:
                'Use fullMount from test_helpers.js instead. After mounting, use @testing-library/vue queries for interactions and assertions.',
            },
            {
              name: '@vue/test-utils',
              message:
                'Do not import from @vue/test-utils in frontend integration specs. Use @testing-library/vue for queries and fullMount from test_helpers.js for mounting.',
            },
            {
              name: '@testing-library/dom',
              message:
                'Import from @testing-library/vue instead of @testing-library/dom. It re-exports everything from @testing-library/dom.',
            },
          ],
          patterns: [
            ...restrictedImportsPatterns,
            {
              group: ['vue'],
              importNames: ['nextTick'],
              message: 'Use waitFor from @testing-library/vue instead of nextTick.',
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
            'Do not use router.push. Simulate user behaviours and assert the resulting HTML.',
        },
        {
          selector:
            'CallExpression[callee.object.property.name=/[Rr]outer/][callee.property.name="push"]',
          message:
            'Do not use router.push. Simulate user behaviours and assert the resulting HTML.',
        },
        {
          selector: 'MemberExpression[object.name=/[Rr]outer/][property.name="currentRoute"]',
          message:
            'Do not access the router properties directly. Simulate user behaviours and assert the resulting HTML.',
        },
        {
          selector: 'MemberExpression[property.name="nextTick"]',
          message: 'Use waitFor from @testing-library/vue instead of nextTick.',
        },
        {
          selector: 'MemberExpression[property.name="$nextTick"]',
          message: 'Use waitFor from @testing-library/vue instead of $nextTick.',
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
        {
          selector: 'MemberExpression[object.name=/[Ss]tore/][property.name="state"]',
          message:
            'Do not access store.state directly. Simulate user behaviours and assert the resulting HTML.',
        },
        {
          selector: 'MemberExpression[object.property.name=/[Ss]tore/][property.name="state"]',
          message:
            'Do not access store.state directly. Simulate user behaviours and assert the resulting HTML.',
        },
      ],
    },
  },

  // Frontend integration tests are EE-only. Block any file from being (re)introduced
  // under the CE path; the harness and fixtures live under ee/spec/frontend/integration/.
  {
    files: ['spec/frontend/integration/**/*'],
    rules: {
      'no-restricted-syntax': [
        'error',
        {
          selector: 'Program',
          message:
            'Frontend integration tests are EE-only; use Capybara for FOSS/licensed behavior. Place this file under ee/spec/frontend/integration/ instead.',
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
      globals: globals.worker,
    },

    rules: {
      // `no-restricted-globals` still bans the `confusing-browser-globals` list.
      // The rule options replace instead of merging, so the full list has to be restated.
      'no-restricted-globals': [
        'error',
        ...restrictedGlobals.filter((entry) => !Object.hasOwn(globals.worker, entry.name ?? entry)),
      ],
    },
  },

  ...jhConfigs,
  ...Object.values(REVEAL_ESLINT_TODO ? {} : todoLists),
];
