const path = require('path');

const { IS_EE, IS_JH, ROOT_PATH } = require('../webpack.constants');
const { CONTEXT_ALIASES } = require('./context_aliases_shared');
const { USE_VUE3 } = require('./vue_version');

const aliases = {
  // Map Apollo client to apollo/client/core to prevent react related imports from being loaded
  '@apollo/client$': '@apollo/client/core',
  '~': path.join(ROOT_PATH, 'app/assets/javascripts'),
  emojis: path.join(ROOT_PATH, 'fixtures/emojis'),
  images: path.join(ROOT_PATH, 'app/assets/images'),
  vendor: path.join(ROOT_PATH, 'vendor/assets/javascripts'),
  jquery$: 'jquery/dist/jquery.slim.js',
  lodash$: 'lodash-es',

  // `raphael/raphael.no-deps` declares `eve` as an external dependency
  // (the package was renamed to `eve-raphael` years ago, but Raphael's
  // UMD wrapper still does `require("eve")`). Alias the bare name to
  // the actual installed package so both webpack and Vite resolve it.
  eve$: 'eve-raphael',
  shared_queries: path.join(ROOT_PATH, 'app/graphql/queries'),

  // the following resolves files which are different between CE and EE
  ee_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // the following resolves files which are different between CE and JH
  jh_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // the following resolves files which are different between CE/EE/JH
  any_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // consume @gitlab-ui from source to allow us to compile in either Vue 2 or Vue 3
  '@gitlab/ui/dist/charts$': '@gitlab/ui/src/charts',
  '@gitlab/ui$': '@gitlab/ui/src',

  // override loader path for icons.svg so we do not duplicate this asset
  '@gitlab/svgs/dist/icons.svg': path.join(
    ROOT_PATH,
    'app/assets/javascripts/lib/utils/icons_path.js',
  ),

  // override loader path for illustrations.svg so we do not duplicate this asset
  '@gitlab/svgs/dist/illustrations.svg': path.join(
    ROOT_PATH,
    'app/assets/javascripts/lib/utils/illustrations_path.js',
  ),

  // prevent loading of index.js to avoid duplicate instances of classes
  graphql: path.join(ROOT_PATH, 'node_modules/graphql/index.mjs'),

  // load mjs version instead of cjs
  'markdown-it': path.join(ROOT_PATH, 'node_modules/markdown-it/index.mjs'),

  // test-environment-only aliases duplicated from Jest config
  'spec/test_constants$': path.join(ROOT_PATH, 'spec/frontend/__helpers__/test_constants'),
  ee_else_ce_jest: path.join(ROOT_PATH, 'spec/frontend'),
  helpers: path.join(ROOT_PATH, 'spec/frontend/__helpers__'),
  jest: path.join(ROOT_PATH, 'spec/frontend'),
  test_fixtures: path.join(ROOT_PATH, 'tmp/tests/frontend/fixtures'),
  test_fixtures_static: path.join(ROOT_PATH, 'spec/frontend/fixtures/static'),
  test_helpers: path.join(ROOT_PATH, 'spec/frontend_integration/test_helpers'),
  public: path.join(ROOT_PATH, 'public'),
  storybook_addons: path.resolve(ROOT_PATH, 'storybook/config/addons'),
  storybook_helpers: path.resolve(ROOT_PATH, 'storybook/helpers'),
};

if (IS_EE) {
  Object.assign(aliases, {
    ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    ee_component: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    ee_images: path.join(ROOT_PATH, 'ee/app/assets/images'),
    ee_else_ce: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    jh_else_ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    any_else_ce: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    fe_islands: path.join(ROOT_PATH, 'ee/frontend_islands/apps'),

    // test-environment-only aliases duplicated from Jest config
    ee_else_ce_jest: path.join(ROOT_PATH, 'ee/spec/frontend'),
    ee_jest: path.join(ROOT_PATH, 'ee/spec/frontend'),
    test_fixtures: path.join(ROOT_PATH, 'tmp/tests/frontend/fixtures-ee'),
  });
}

if (IS_JH) {
  Object.assign(aliases, {
    jh: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    jh_component: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    jh_images: path.join(ROOT_PATH, 'jh/app/assets/images'),
    // jh path alias https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74305#note_732793956
    jh_else_ce: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    jh_else_ee: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    any_else_ce: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),

    // test-environment-only aliases duplicated from Jest config
    jh_jest: path.join(ROOT_PATH, 'jh/spec/frontend'),
  });
}

if (USE_VUE3) {
  Object.assign(aliases, CONTEXT_ALIASES);
}

module.exports = { aliases };
