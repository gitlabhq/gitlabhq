// eslint-disable-next-line import/order
const crypto = require('./helpers/patched_crypto');

const { VUE_VERSION: EXPLICIT_VUE_VERSION } = process.env;
if (![undefined, '2', '3'].includes(EXPLICIT_VUE_VERSION)) {
  throw new Error(
    `Invalid VUE_VERSION value: ${EXPLICIT_VUE_VERSION}. Only '2' and '3' are supported`,
  );
}
const USE_VUE3 = EXPLICIT_VUE_VERSION === '3';

if (USE_VUE3) {
  console.log('[V] Using Vue.js 3');
}
const VUE_LOADER_MODULE = USE_VUE3 ? 'vue-loader-vue3' : 'vue-loader';

const fs = require('fs');
const path = require('path');

const BABEL_VERSION = require('@babel/core/package.json').version;
const SOURCEGRAPH_VERSION = require('@sourcegraph/code-host-integration/package.json').version;
const GITLAB_WEB_IDE_VERSION = require('@gitlab/web-ide/package.json').version;

const BABEL_LOADER_VERSION = require('babel-loader/package.json').version;
const CompressionPlugin = require('compression-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const glob = require('glob');
// eslint-disable-next-line import/no-dynamic-require
const { VueLoaderPlugin } = require(VUE_LOADER_MODULE);
// eslint-disable-next-line import/no-dynamic-require
const VUE_LOADER_VERSION = require(`${VUE_LOADER_MODULE}/package.json`).version;
const VUE_VERSION = require('vue/package.json').version;

const webpack = require('webpack');
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
const { StatsWriterPlugin } = require('webpack-stats-plugin');
const WEBPACK_VERSION = require('webpack/package.json').version;
const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');

const createIncrementalWebpackCompiler = require('./helpers/incremental_webpack_compiler');
const IS_EE = require('./helpers/is_ee_env');
const IS_JH = require('./helpers/is_jh_env');
const vendorDllHash = require('./helpers/vendor_dll_hash');

const GraphqlKnownOperationsPlugin = require('./plugins/graphql_known_operations_plugin');

const ROOT_PATH = path.resolve(__dirname, '..');
const SUPPORTED_BROWSERS = fs.readFileSync(path.join(ROOT_PATH, '.browserslistrc'), 'utf-8');
const SUPPORTED_BROWSERS_HASH = crypto
  .createHash('sha256')
  .update(SUPPORTED_BROWSERS)
  .digest('hex');

const VENDOR_DLL = process.env.WEBPACK_VENDOR_DLL && process.env.WEBPACK_VENDOR_DLL !== 'false';
const CACHE_PATH = process.env.WEBPACK_CACHE_PATH || path.join(ROOT_PATH, 'tmp/cache');
const IS_PRODUCTION = process.env.NODE_ENV === 'production';
const IS_DEV_SERVER = process.env.WEBPACK_SERVE === 'true';

const { DEV_SERVER_HOST, DEV_SERVER_PUBLIC_ADDR } = process.env;
const DEV_SERVER_PORT = parseInt(process.env.DEV_SERVER_PORT, 10);
const DEV_SERVER_ALLOWED_HOSTS =
  process.env.DEV_SERVER_ALLOWED_HOSTS && process.env.DEV_SERVER_ALLOWED_HOSTS.split(',');
const DEV_SERVER_LIVERELOAD = IS_DEV_SERVER && process.env.DEV_SERVER_LIVERELOAD !== 'false';
const INCREMENTAL_COMPILER_ENABLED =
  IS_DEV_SERVER &&
  process.env.DEV_SERVER_INCREMENTAL &&
  process.env.DEV_SERVER_INCREMENTAL !== 'false';
const INCREMENTAL_COMPILER_TTL = Number(process.env.DEV_SERVER_INCREMENTAL_TTL) || Infinity;
const INCREMENTAL_COMPILER_RECORD_HISTORY = IS_DEV_SERVER && !process.env.CI;
const WEBPACK_REPORT = process.env.WEBPACK_REPORT && process.env.WEBPACK_REPORT !== 'false';
const WEBPACK_MEMORY_TEST =
  process.env.WEBPACK_MEMORY_TEST && process.env.WEBPACK_MEMORY_TEST !== 'false';
let NO_COMPRESSION = process.env.NO_COMPRESSION && process.env.NO_COMPRESSION !== 'false';
let NO_SOURCEMAPS = process.env.NO_SOURCEMAPS && process.env.NO_SOURCEMAPS !== 'false';
let NO_HASHED_CHUNKS = process.env.NO_HASHED_CHUNKS && process.env.NO_HASHED_CHUNKS !== 'false';

if (WEBPACK_REPORT) {
  console.log('Webpack report enabled. Running a "slim" production build.');
  // For our webpack report we need no source maps, compression _or_ hashed file names.
  NO_SOURCEMAPS = true;
  NO_COMPRESSION = true;
  NO_HASHED_CHUNKS = true;
}

const WEBPACK_OUTPUT_PATH = path.join(ROOT_PATH, 'public/assets/webpack');
const WEBPACK_PUBLIC_PATH = '/assets/webpack/';
const SOURCEGRAPH_PACKAGE = '@sourcegraph/code-host-integration';
const GITLAB_WEB_IDE_PACKAGE = '@gitlab/web-ide';

const SOURCEGRAPH_PATH = path.join('sourcegraph', SOURCEGRAPH_VERSION, '/');
const SOURCEGRAPH_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, SOURCEGRAPH_PATH);
const SOURCEGRAPH_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, SOURCEGRAPH_PATH);

const GITLAB_WEB_IDE_PATH = path.join('gitlab-vscode', GITLAB_WEB_IDE_VERSION, '/');
const GITLAB_WEB_IDE_OUTPUT_PATH = path.join(WEBPACK_OUTPUT_PATH, GITLAB_WEB_IDE_PATH);
const GITLAB_WEB_IDE_PUBLIC_PATH = path.join(WEBPACK_PUBLIC_PATH, GITLAB_WEB_IDE_PATH);

const devtool = IS_PRODUCTION ? 'source-map' : 'cheap-module-eval-source-map';

let autoEntriesCount = 0;
let watchAutoEntries = [];
const defaultEntries = ['./main'];

const incrementalCompiler = createIncrementalWebpackCompiler(
  INCREMENTAL_COMPILER_RECORD_HISTORY,
  INCREMENTAL_COMPILER_ENABLED,
  path.join(CACHE_PATH, 'incremental-webpack-compiler-history.json'),
  INCREMENTAL_COMPILER_TTL,
);

function generateEntries() {
  // generate automatic entry points
  const autoEntries = {};
  const autoEntriesMap = {};
  const pageEntries = glob.sync('pages/**/index.js', {
    cwd: path.join(ROOT_PATH, 'app/assets/javascripts'),
  });
  watchAutoEntries = [path.join(ROOT_PATH, 'app/assets/javascripts/pages/')];

  function generateAutoEntries(entryPath, prefix = '.') {
    const chunkPath = entryPath.replace(/\/index\.js$/, '');
    const chunkName = chunkPath.replace(/\//g, '.');
    autoEntriesMap[chunkName] = `${prefix}/${entryPath}`;
  }

  pageEntries.forEach((entryPath) => generateAutoEntries(entryPath));

  if (IS_EE) {
    const eePageEntries = glob.sync('pages/**/index.js', {
      cwd: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    });
    eePageEntries.forEach((entryPath) => generateAutoEntries(entryPath, 'ee'));
    watchAutoEntries.push(path.join(ROOT_PATH, 'ee/app/assets/javascripts/pages/'));
  }

  if (IS_JH) {
    const eePageEntries = glob.sync('pages/**/index.js', {
      cwd: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    });
    eePageEntries.forEach((entryPath) => generateAutoEntries(entryPath, 'jh'));
    watchAutoEntries.push(path.join(ROOT_PATH, 'jh/app/assets/javascripts/pages/'));
  }

  const autoEntryKeys = Object.keys(autoEntriesMap);
  autoEntriesCount = autoEntryKeys.length;

  // import ancestor entrypoints within their children
  autoEntryKeys.forEach((entry) => {
    const entryPaths = [autoEntriesMap[entry]];
    const segments = entry.split('.');
    while (segments.pop()) {
      const ancestor = segments.join('.');
      if (autoEntryKeys.includes(ancestor)) {
        entryPaths.unshift(autoEntriesMap[ancestor]);
      }
    }
    autoEntries[entry] = defaultEntries.concat(entryPaths);
  });

  /*
  If you create manual entries, ensure that these import `app/assets/javascripts/webpack.js` right at
  the top of the entry in order to ensure that the public path is correctly determined for loading
  assets async. See: https://webpack.js.org/configuration/output/#outputpublicpath

  Note: WebPack 5 has an 'auto' option for the public path which could allow us to remove this option
  Note 2: If you are using web-workers, you might need to reset the public path, see:
  https://gitlab.com/gitlab-org/gitlab/-/issues/321656
   */

  const manualEntries = {
    default: defaultEntries,
    legacy_sentry: './sentry/legacy_index.js',
    sentry: './sentry/index.js',
    performance_bar: './performance_bar/index.js',
    jira_connect_app: './jira_connect/subscriptions/index.js',
    sandboxed_mermaid: './lib/mermaid.js',
    redirect_listbox: './entrypoints/behaviors/redirect_listbox.js',
    sandboxed_swagger: './lib/swagger.js',
    super_sidebar: './entrypoints/super_sidebar.js',
    tracker: './entrypoints/tracker.js',
  };

  return Object.assign(manualEntries, incrementalCompiler.filterEntryPoints(autoEntries));
}

const alias = {
  // Map Apollo client to apollo/client/core to prevent react related imports from being loaded
  '@apollo/client$': '@apollo/client/core',
  // Map Sentry calls to use local wrapper
  '@sentry/browser$': path.join(
    ROOT_PATH,
    'app/assets/javascripts/sentry/sentry_browser_wrapper.js',
  ),
  '~': path.join(ROOT_PATH, 'app/assets/javascripts'),
  emojis: path.join(ROOT_PATH, 'fixtures/emojis'),
  empty_states: path.join(ROOT_PATH, 'app/views/shared/empty_states'),
  icons: path.join(ROOT_PATH, 'app/views/shared/icons'),
  images: path.join(ROOT_PATH, 'app/assets/images'),
  vendor: path.join(ROOT_PATH, 'vendor/assets/javascripts'),
  jquery$: 'jquery/dist/jquery.slim.js',
  shared_queries: path.join(ROOT_PATH, 'app/graphql/queries'),

  // the following resolves files which are different between CE and EE
  ee_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // the following resolves files which are different between CE and JH
  jh_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // the following resolves files which are different between CE/EE/JH
  any_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // override loader path for icons.svg so we do not duplicate this asset
  '@gitlab/svgs/dist/icons.svg': path.join(
    ROOT_PATH,
    'app/assets/javascripts/lib/utils/icons_path.js',
  ),

  // test-environment-only aliases duplicated from Jest config
  'spec/test_constants$': path.join(ROOT_PATH, 'spec/frontend/__helpers__/test_constants'),
  ee_else_ce_jest: path.join(ROOT_PATH, 'spec/frontend'),
  helpers: path.join(ROOT_PATH, 'spec/frontend/__helpers__'),
  jest: path.join(ROOT_PATH, 'spec/frontend'),
  test_fixtures: path.join(ROOT_PATH, 'tmp/tests/frontend/fixtures'),
  test_fixtures_static: path.join(ROOT_PATH, 'spec/frontend/fixtures/static'),
  test_helpers: path.join(ROOT_PATH, 'spec/frontend_integration/test_helpers'),
  public: path.join(ROOT_PATH, 'public'),
};

if (IS_EE) {
  Object.assign(alias, {
    ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    ee_component: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    ee_empty_states: path.join(ROOT_PATH, 'ee/app/views/shared/empty_states'),
    ee_icons: path.join(ROOT_PATH, 'ee/app/views/shared/icons'),
    ee_images: path.join(ROOT_PATH, 'ee/app/assets/images'),
    ee_else_ce: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    jh_else_ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    any_else_ce: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),

    // test-environment-only aliases duplicated from Jest config
    ee_else_ce_jest: path.join(ROOT_PATH, 'ee/spec/frontend'),
    ee_jest: path.join(ROOT_PATH, 'ee/spec/frontend'),
    test_fixtures: path.join(ROOT_PATH, 'tmp/tests/frontend/fixtures-ee'),
  });
}

if (IS_JH) {
  Object.assign(alias, {
    jh: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    jh_component: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    jh_empty_states: path.join(ROOT_PATH, 'jh/app/views/shared/empty_states'),
    jh_icons: path.join(ROOT_PATH, 'jh/app/views/shared/icons'),
    jh_images: path.join(ROOT_PATH, 'jh/app/assets/images'),
    // jh path alias https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74305#note_732793956
    jh_else_ce: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    jh_else_ee: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),
    any_else_ce: path.join(ROOT_PATH, 'jh/app/assets/javascripts'),

    // test-environment-only aliases duplicated from Jest config
    jh_jest: path.join(ROOT_PATH, 'jh/spec/frontend'),
  });
}

let dll;

if (VENDOR_DLL && !IS_PRODUCTION) {
  const dllHash = vendorDllHash();
  const dllCachePath = path.join(ROOT_PATH, `tmp/cache/webpack-dlls/${dllHash}`);
  dll = {
    manifestPath: path.join(dllCachePath, 'vendor.dll.manifest.json'),
    cacheFrom: dllCachePath,
    cacheTo: path.join(WEBPACK_OUTPUT_PATH, `dll.${dllHash}/`),
    publicPath: `dll.${dllHash}/vendor.dll.bundle.js`,
    exists: null,
  };
}

const defaultJsOptions = {
  cacheDirectory: path.join(CACHE_PATH, 'babel-loader'),
  cacheIdentifier: [
    process.env.BABEL_ENV || process.env.NODE_ENV || 'development',
    webpack.version,
    BABEL_VERSION,
    BABEL_LOADER_VERSION,
    // Ensure that changing supported browsers will refresh the cache
    // in order to not pull in outdated files that import core-js
    SUPPORTED_BROWSERS_HASH,
  ].join('|'),
  cacheCompression: false,
};

const vueLoaderOptions = {
  ident: 'vue-loader-options',

  cacheDirectory: path.join(CACHE_PATH, 'vue-loader'),
  cacheIdentifier: [
    process.env.NODE_ENV || 'development',
    webpack.version,
    VUE_VERSION,
    VUE_LOADER_VERSION,
    EXPLICIT_VUE_VERSION,
  ].join('|'),
};

let shouldExcludeFromCompliling = (modulePath) =>
  /node_modules|vendor[\\/]assets/.test(modulePath) && !/\.vue\.js/.test(modulePath);
// We explicitly set VUE_VERSION
// Use @gitlab-ui from source to allow us to dig differences
// between Vue.js 2 and Vue.js 3 while using built gitlab-ui by default
if (EXPLICIT_VUE_VERSION) {
  Object.assign(alias, {
    '@gitlab/ui/scss_to_js': path.join(ROOT_PATH, 'node_modules/@gitlab/ui/scss_to_js'),
    '@gitlab/ui/dist': '@gitlab/ui/src',
    '@gitlab/ui': '@gitlab/ui/src',
  });

  const originalShouldExcludeFromCompliling = shouldExcludeFromCompliling;

  shouldExcludeFromCompliling = (modulePath) =>
    originalShouldExcludeFromCompliling(modulePath) &&
    !/node_modules[\\/]@gitlab[\\/]ui/.test(modulePath) &&
    !/node_modules[\\/]bootstrap-vue[\\/]src[\\/]vue\.js/.test(modulePath);
}

if (USE_VUE3) {
  Object.assign(alias, {
    // ensure we always use the same type of module for Vue
    vue: '@vue/compat/dist/vue.runtime.esm-bundler.js',
    vuex: path.join(ROOT_PATH, 'app/assets/javascripts/lib/utils/vue3compat/vuex.js'),
    'vue-apollo': path.join(ROOT_PATH, 'app/assets/javascripts/lib/utils/vue3compat/vue_apollo.js'),
    'vue-router': path.join(ROOT_PATH, 'app/assets/javascripts/lib/utils/vue3compat/vue_router.js'),
  });

  vueLoaderOptions.compiler = require.resolve('./vue3migration/compiler');
}

module.exports = {
  mode: IS_PRODUCTION ? 'production' : 'development',

  context: path.join(ROOT_PATH, 'app/assets/javascripts'),

  entry: generateEntries,

  output: {
    path: WEBPACK_OUTPUT_PATH,
    publicPath: WEBPACK_PUBLIC_PATH,
    filename:
      IS_PRODUCTION && !NO_HASHED_CHUNKS ? '[name].[contenthash:8].bundle.js' : '[name].bundle.js',
    chunkFilename:
      IS_PRODUCTION && !NO_HASHED_CHUNKS ? '[name].[contenthash:8].chunk.js' : '[name].chunk.js',
    globalObject: 'this', // allow HMR and web workers to play nice
  },

  resolve: {
    extensions: ['.js'],
    alias,
  },

  module: {
    strictExportPresence: true,
    rules: [
      {
        type: 'javascript/auto',
        test: /\.mjs$/,
        use: [],
      },
      {
        test: /(@cubejs-client\/vue).*\.(js)?$/,
        include: /node_modules/,
        loader: 'babel-loader',
      },
      {
        test: /mermaid\/.*\.js?$/,
        include: /node_modules/,
        loader: 'babel-loader',
      },
      {
        test: /\.(js|cjs)$/,
        exclude: shouldExcludeFromCompliling,
        use: [
          {
            loader: 'thread-loader',
            options: {
              workerParallelJobs: 20,
              poolRespawn: false,
              poolParallelJobs: 200,
              poolTimeout: DEV_SERVER_LIVERELOAD ? Infinity : 5000,
            },
          },
          {
            loader: 'babel-loader',
            options: defaultJsOptions,
          },
        ],
      },
      {
        test: /\.(js|cjs)$/,
        include: (modulePath) =>
          /node_modules\/(monaco-worker-manager|monaco-marker-data-provider)\/index\.js/.test(
            modulePath,
          ) || /node_modules\/yaml/.test(modulePath),
        loader: 'babel-loader',
        options: {
          plugins: ['@babel/plugin-proposal-numeric-separator'],
          ...defaultJsOptions,
        },
      },
      {
        test: /\.vue$/,
        loader: VUE_LOADER_MODULE,
        options: vueLoaderOptions,
      },
      {
        test: /\.(graphql|gql)$/,
        exclude: /node_modules/,
        loader: 'graphql-tag/loader',
      },
      {
        test: /icons\.svg$/,
        loader: 'file-loader',
        options: {
          name: '[name].[contenthash:8].[ext]',
        },
      },
      {
        test: /\.svg$/,
        exclude: /icons\.svg$/,
        oneOf: [
          {
            resourceQuery: /url/,
            loader: 'file-loader',
            options: {
              name: '[name].[contenthash:8].[ext]',
              esModule: false,
            },
          },
          {
            loader: 'raw-loader',
          },
        ],
      },
      {
        test: /\.(gif|png|mp4)$/,
        loader: 'url-loader',
        options: { limit: 2048 },
      },
      {
        test: /_worker\.js$/,
        resourceQuery: /worker/,
        use: [
          {
            loader: 'worker-loader',
            options: {
              name: '[name].[contenthash:8].worker.js',
              inline: IS_DEV_SERVER,
            },
          },
          'babel-loader',
        ],
      },
      {
        test: /\.(worker(\.min)?\.js|pdf)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
        options: {
          name: '[name].[contenthash:8].[ext]',
        },
      },
      {
        test: /.css$/,
        use: [
          'style-loader',
          {
            loader: 'css-loader',
            options: {
              modules: 'global',
              localIdentName: '[name].[contenthash:8].[ext]',
            },
          },
        ],
      },
      {
        test: /\.(eot|ttf|woff|woff2)$/,
        include: /node_modules\/(katex\/dist\/fonts|monaco-editor)/,
        loader: 'file-loader',
        options: {
          name: '[name].[contenthash:8].[ext]',
          esModule: false,
        },
      },
      {
        test: /editor\/schema\/.+\.json$/,
        type: 'javascript/auto',
        loader: 'file-loader',
        options: {
          name: '[name].[contenthash:8].[ext]',
        },
      },
      {
        resourceQuery: /raw/,
        loader: 'raw-loader',
      },
    ].filter(Boolean),
  },

  optimization: {
    // Replace 'hashed' with 'deterministic' in webpack 5
    moduleIds: 'hashed',
    runtimeChunk: 'single',
    splitChunks: {
      maxInitialRequests: 20,
      // In order to prevent firewalls tripping up: https://gitlab.com/gitlab-org/gitlab/-/issues/22648
      automaticNameDelimiter: '-',
      cacheGroups: {
        default: false,
        common: () => ({
          priority: 20,
          name: 'main',
          chunks: 'initial',
          minChunks: autoEntriesCount * 0.9,
        }),
        prosemirror: {
          priority: 17,
          name: 'prosemirror',
          chunks: 'all',
          test: /[\\/]node_modules[\\/]prosemirror.*?[\\/]/,
          minChunks: 2,
          reuseExistingChunk: true,
        },
        graphql: {
          priority: 16,
          name: 'graphql',
          chunks: 'all',
          test: /[\\/]node_modules[\\/][^\\/]*(immer|apollo|graphql|zen-observable)[^\\/]*[\\/]/,
          minChunks: 2,
          reuseExistingChunk: true,
        },
        monaco: {
          priority: 15,
          name: 'monaco',
          chunks: 'all',
          test: /[\\/]node_modules[\\/]monaco-editor[\\/]/,
          minChunks: 2,
          reuseExistingChunk: true,
        },
        echarts: {
          priority: 14,
          name: 'echarts',
          chunks: 'all',
          test: /[\\/]node_modules[\\/](echarts|zrender)[\\/]/,
          minChunks: 2,
          reuseExistingChunk: true,
        },
        security_reports: {
          priority: 13,
          name: 'security_reports',
          chunks: 'initial',
          test: /[\\/](vue_shared[\\/](security_reports|license_compliance)|security_dashboard)[\\/]/,
          minChunks: 2,
          reuseExistingChunk: true,
        },
        vendors: {
          priority: 10,
          chunks: 'async',
          test: /[\\/](node_modules|vendor[\\/]assets[\\/]javascripts)[\\/]/,
        },
        commons: {
          chunks: 'all',
          minChunks: 2,
          reuseExistingChunk: true,
        },
      },
    },
  },

  plugins: [
    // manifest filename must match config.webpack.manifest_filename
    // webpack-rails only needs assetsByChunkName to function properly
    new StatsWriterPlugin({
      filename: 'manifest.json',
      transform(data, opts) {
        const stats = opts.compiler.getStats().toJson({
          chunkModules: false,
          source: false,
          chunks: false,
          modules: false,
          assets: true,
          errors: !IS_PRODUCTION,
          warnings: !IS_PRODUCTION,
        });

        // tell our rails helper where to find the DLL files
        if (dll) {
          stats.dllAssets = dll.publicPath;
        }
        return JSON.stringify(stats, null, 2);
      },
    }),

    // enable vue-loader to use existing loader rules for other module types
    new VueLoaderPlugin(),

    // automatically configure monaco editor web workers
    new MonacoWebpackPlugin({
      filename: '[name].[contenthash:8].worker.js',
      customLanguages: [
        {
          label: 'yaml',
          entry: 'monaco-yaml',
          worker: {
            id: 'monaco-yaml/yamlWorker',
            entry: 'monaco-yaml/yaml.worker',
          },
        },
      ],
    }),

    new GraphqlKnownOperationsPlugin({ filename: 'graphql_known_operations.yml' }),

    // fix legacy jQuery plugins which depend on globals
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
    }),

    // if DLLs are enabled, detect whether the DLL exists and create it automatically if necessary
    dll && {
      apply(compiler) {
        compiler.hooks.beforeCompile.tapAsync('DllAutoCompilePlugin', (params, callback) => {
          if (dll.exists) {
            callback();
          } else if (fs.existsSync(dll.manifestPath)) {
            console.log(`Using vendor DLL found at: ${dll.cacheFrom}`);
            dll.exists = true;
            callback();
          } else {
            console.log(
              `Warning: No vendor DLL found at: ${dll.cacheFrom}. Compiling DLL automatically.`,
            );

            // eslint-disable-next-line global-require
            const dllConfig = require('./webpack.vendor.config');
            const dllCompiler = webpack(dllConfig);

            dllCompiler.run((err, stats) => {
              if (err) {
                return callback(err);
              }

              const info = stats.toJson();

              if (stats.hasErrors()) {
                console.error(info.errors.join('\n\n'));
                return callback('DLL not compiled successfully.');
              }

              if (stats.hasWarnings()) {
                console.warn(info.warnings.join('\n\n'));
                console.warn('DLL compiled with warnings.');
              } else {
                console.log('DLL compiled successfully.');
              }

              dll.exists = true;
              return callback();
            });
          }
        });
      },
    },

    // reference our compiled DLL modules
    dll &&
      new webpack.DllReferencePlugin({
        context: ROOT_PATH,
        manifest: dll.manifestPath,
      }),

    dll &&
      new CopyWebpackPlugin({
        patterns: [
          {
            from: dll.cacheFrom,
            to: dll.cacheTo,
          },
        ],
      }),

    !IS_EE &&
      new webpack.NormalModuleReplacementPlugin(/^ee_component\/(.*)\.vue/, (resource) => {
        // eslint-disable-next-line no-param-reassign
        resource.request = path.join(
          ROOT_PATH,
          'app/assets/javascripts/vue_shared/components/empty_component.js',
        );
      }),

    new webpack.NormalModuleReplacementPlugin(/markdown-it/, (resource) => {
      // eslint-disable-next-line no-param-reassign
      resource.request = path.join(ROOT_PATH, 'app/assets/javascripts/lib/markdown_it.js');
    }),

    !IS_JH &&
      new webpack.NormalModuleReplacementPlugin(/^jh_component\/(.*)\.vue/, (resource) => {
        // eslint-disable-next-line no-param-reassign
        resource.request = path.join(
          ROOT_PATH,
          'app/assets/javascripts/vue_shared/components/empty_component.js',
        );
      }),

    new CopyWebpackPlugin({
      patterns: [
        {
          from: path.join(ROOT_PATH, 'node_modules/pdfjs-dist/cmaps/'),
          to: path.join(WEBPACK_OUTPUT_PATH, 'pdfjs/cmaps/'),
        },
        {
          from: path.join(ROOT_PATH, 'node_modules/pdfjs-dist/legacy/build/pdf.worker.min.js'),
          to: path.join(WEBPACK_OUTPUT_PATH, 'pdfjs/'),
        },
        {
          from: path.join(ROOT_PATH, 'node_modules', SOURCEGRAPH_PACKAGE, '/'),
          to: SOURCEGRAPH_OUTPUT_PATH,
          globOptions: {
            ignore: ['package.json'],
          },
        },
        {
          from: path.join(ROOT_PATH, 'node_modules', GITLAB_WEB_IDE_PACKAGE, 'dist', 'public'),
          to: GITLAB_WEB_IDE_OUTPUT_PATH,
        },
        {
          from: path.join(
            ROOT_PATH,
            'node_modules/@gitlab/visual-review-tools/dist/visual_review_toolbar.js',
          ),
          to: WEBPACK_OUTPUT_PATH,
        },
      ],
    }),

    // compression can require a lot of compute time and is disabled in CI
    IS_PRODUCTION && !NO_COMPRESSION && new CompressionPlugin(),

    // WatchForChangesPlugin
    // TODO: publish this as a separate plugin
    IS_DEV_SERVER && {
      apply(compiler) {
        compiler.hooks.emit.tapAsync('WatchForChangesPlugin', (compilation, callback) => {
          const missingDeps = Array.from(compilation.missingDependencies);
          const nodeModulesPath = path.join(ROOT_PATH, 'node_modules');
          const hasMissingNodeModules = missingDeps.some(
            (file) => file.indexOf(nodeModulesPath) !== -1,
          );

          // watch for changes to missing node_modules
          if (hasMissingNodeModules) compilation.contextDependencies.add(nodeModulesPath);

          // watch for changes to automatic entrypoints
          watchAutoEntries.forEach((watchPath) => compilation.contextDependencies.add(watchPath));

          // report our auto-generated bundle count
          if (incrementalCompiler.enabled) {
            incrementalCompiler.logStatus(autoEntriesCount);
          } else {
            console.log(
              `${autoEntriesCount} entries from '/pages' automatically added to webpack output.`,
            );
          }

          callback();
        });
      },
    },

    // output the in-memory heap size upon compilation and exit
    WEBPACK_MEMORY_TEST && {
      apply(compiler) {
        compiler.hooks.emit.tapAsync('ReportMemoryConsumptionPlugin', () => {
          console.log('Assets compiled...');
          if (global.gc) {
            console.log('Running garbage collection...');
            global.gc();
          } else {
            console.error(
              "WARNING: you must use the --expose-gc node option to accurately measure webpack's heap size",
            );
          }
          const memoryUsage = process.memoryUsage().heapUsed;
          const toMB = (bytes) => Math.floor(bytes / 1024 / 1024);

          console.log(`Webpack heap size: ${toMB(memoryUsage)} MB`);

          const webpackStatistics = {
            memoryUsage,
            date: Date.now(), // milliseconds
            commitSHA: process.env.CI_COMMIT_SHA,
            nodeVersion: process.versions.node,
            webpackVersion: WEBPACK_VERSION,
          };

          console.log(webpackStatistics);

          fs.writeFileSync(
            path.join(ROOT_PATH, 'webpack-dev-server.json'),
            JSON.stringify(webpackStatistics),
          );

          // exit in case we're running webpack-dev-server
          if (IS_DEV_SERVER) {
            process.exit();
          }
        });
      },
    },

    // optionally generate webpack bundle analysis
    WEBPACK_REPORT &&
      new BundleAnalyzerPlugin({
        analyzerMode: 'static',
        generateStatsFile: true,
        openAnalyzer: false,
        reportFilename: path.join(ROOT_PATH, 'webpack-report/index.html'),
        statsFilename: path.join(ROOT_PATH, 'webpack-report/stats.json'),
        statsOptions: {
          source: false,
          errors: false,
          warnings: false,
        },
      }),

    new webpack.DefinePlugin({
      // These are used to define window.gon.ee, window.gon.jh and other things properly in tests:
      'process.env.IS_EE': JSON.stringify(IS_EE),
      'process.env.IS_JH': JSON.stringify(IS_JH),
      // These are used to check against "EE" properly in application code
      IS_EE: IS_EE ? 'window.gon && window.gon.ee' : JSON.stringify(false),
      IS_JH: IS_JH ? 'window.gon && window.gon.jh' : JSON.stringify(false),
      // This is used by Sourcegraph because these assets are loaded dnamically
      'process.env.SOURCEGRAPH_PUBLIC_PATH': JSON.stringify(SOURCEGRAPH_PUBLIC_PATH),
      'process.env.GITLAB_WEB_IDE_PUBLIC_PATH': JSON.stringify(GITLAB_WEB_IDE_PUBLIC_PATH),
      ...(IS_PRODUCTION ? {} : { LIVE_RELOAD: DEV_SERVER_LIVERELOAD }),
    }),

    /* Pikaday has a optional dependency to moment.
       We are currently not utilizing moment.
       Ignoring this import removes warning from our development build.
       Upstream reference:
       https://github.com/Pikaday/Pikaday/blob/5c1a7559be/pikaday.js#L14
    */
    new webpack.IgnorePlugin(/moment/, /pikaday/),
  ].filter(Boolean),

  devServer: {
    setupMiddlewares: (middlewares, devServer) => {
      if (!devServer) {
        throw new Error('webpack-dev-server is not defined');
      }

      const incrementalCompilerMiddleware = incrementalCompiler.createMiddleware(devServer);

      if (incrementalCompilerMiddleware) {
        middlewares.unshift({
          name: 'incremental-compiler',
          middleware: incrementalCompilerMiddleware,
        });
      }

      return middlewares;
    },
    // Only print errors to CLI
    devMiddleware: {
      stats: 'errors-only',
    },
    host: DEV_SERVER_HOST || 'localhost',
    port: DEV_SERVER_PORT || 3808,
    // Setting up hot module reloading
    // HMR works by setting up a websocket server and injecting
    // a client script which connects to that server.
    // The server will push messages to the client to reload parts
    // of the JavaScript or reload the page if necessary
    webSocketServer: DEV_SERVER_LIVERELOAD ? 'ws' : false,
    hot: DEV_SERVER_LIVERELOAD,
    liveReload: DEV_SERVER_LIVERELOAD,
    // The following settings are mainly needed for HMR support in gitpod.
    // Per default only local hosts are allowed, but here we could
    // allow different hosts (e.g. ['.gitpod'], all of gitpod),
    // as the webpack server will run on a different subdomain than
    // the rails application
    ...(DEV_SERVER_ALLOWED_HOSTS ? { allowedHosts: DEV_SERVER_ALLOWED_HOSTS } : {}),
    client: {
      ...(DEV_SERVER_PUBLIC_ADDR ? { webSocketURL: DEV_SERVER_PUBLIC_ADDR } : {}),
    },
  },

  devtool: NO_SOURCEMAPS ? false : devtool,

  node: {
    fs: 'empty', // editorconfig requires 'fs'
    setImmediate: false,
  },
};
