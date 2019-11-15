const path = require('path');
const glob = require('glob');
const webpack = require('webpack');
const VueLoaderPlugin = require('vue-loader/lib/plugin');
const StatsWriterPlugin = require('webpack-stats-plugin').StatsWriterPlugin;
const CompressionPlugin = require('compression-webpack-plugin');
const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;
const CopyWebpackPlugin = require('copy-webpack-plugin');

const ROOT_PATH = path.resolve(__dirname, '..');
const CACHE_PATH = process.env.WEBPACK_CACHE_PATH || path.join(ROOT_PATH, 'tmp/cache');
const IS_PRODUCTION = process.env.NODE_ENV === 'production';
const IS_DEV_SERVER = process.env.WEBPACK_DEV_SERVER === 'true';
const IS_EE = require('./helpers/is_ee_env');
const DEV_SERVER_HOST = process.env.DEV_SERVER_HOST || 'localhost';
const DEV_SERVER_PORT = parseInt(process.env.DEV_SERVER_PORT, 10) || 3808;
const DEV_SERVER_LIVERELOAD = IS_DEV_SERVER && process.env.DEV_SERVER_LIVERELOAD !== 'false';
const WEBPACK_REPORT = process.env.WEBPACK_REPORT;
const WEBPACK_MEMORY_TEST = process.env.WEBPACK_MEMORY_TEST;
const NO_COMPRESSION = process.env.NO_COMPRESSION;
const NO_SOURCEMAPS = process.env.NO_SOURCEMAPS;

const VUE_VERSION = require('vue/package.json').version;
const VUE_LOADER_VERSION = require('vue-loader/package.json').version;

const devtool = IS_PRODUCTION ? 'source-map' : 'cheap-module-eval-source-map';

let autoEntriesCount = 0;
let watchAutoEntries = [];
const defaultEntries = ['./main'];

function generateEntries() {
  // generate automatic entry points
  const autoEntries = {};
  const autoEntriesMap = {};
  const pageEntries = glob.sync('pages/**/index.js', {
    cwd: path.join(ROOT_PATH, 'app/assets/javascripts'),
  });
  watchAutoEntries = [path.join(ROOT_PATH, 'app/assets/javascripts/pages/')];

  function generateAutoEntries(path, prefix = '.') {
    const chunkPath = path.replace(/\/index\.js$/, '');
    const chunkName = chunkPath.replace(/\//g, '.');
    autoEntriesMap[chunkName] = `${prefix}/${path}`;
  }

  pageEntries.forEach(path => generateAutoEntries(path));

  if (IS_EE) {
    const eePageEntries = glob.sync('pages/**/index.js', {
      cwd: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    });
    eePageEntries.forEach(path => generateAutoEntries(path, 'ee'));
    watchAutoEntries.push(path.join(ROOT_PATH, 'ee/app/assets/javascripts/pages/'));
  }

  const autoEntryKeys = Object.keys(autoEntriesMap);
  autoEntriesCount = autoEntryKeys.length;

  // import ancestor entrypoints within their children
  autoEntryKeys.forEach(entry => {
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

  const manualEntries = {
    default: defaultEntries,
    sentry: './sentry/index.js',
  };

  return Object.assign(manualEntries, autoEntries);
}

const alias = {
  '~': path.join(ROOT_PATH, 'app/assets/javascripts'),
  emojis: path.join(ROOT_PATH, 'fixtures/emojis'),
  empty_states: path.join(ROOT_PATH, 'app/views/shared/empty_states'),
  icons: path.join(ROOT_PATH, 'app/views/shared/icons'),
  images: path.join(ROOT_PATH, 'app/assets/images'),
  vendor: path.join(ROOT_PATH, 'vendor/assets/javascripts'),
  vue$: 'vue/dist/vue.esm.js',
  spec: path.join(ROOT_PATH, 'spec/javascripts'),

  // the following resolves files which are different between CE and EE
  ee_else_ce: path.join(ROOT_PATH, 'app/assets/javascripts'),

  // override loader path for icons.svg so we do not duplicate this asset
  '@gitlab/svgs/dist/icons.svg': path.join(
    ROOT_PATH,
    'app/assets/javascripts/lib/utils/icons_path.js',
  ),
};

if (IS_EE) {
  Object.assign(alias, {
    ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
    ee_empty_states: path.join(ROOT_PATH, 'ee/app/views/shared/empty_states'),
    ee_icons: path.join(ROOT_PATH, 'ee/app/views/shared/icons'),
    ee_images: path.join(ROOT_PATH, 'ee/app/assets/images'),
    ee_spec: path.join(ROOT_PATH, 'ee/spec/javascripts'),
    ee_else_ce: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
  });
}

module.exports = {
  mode: IS_PRODUCTION ? 'production' : 'development',

  context: path.join(ROOT_PATH, 'app/assets/javascripts'),

  entry: generateEntries,

  output: {
    path: path.join(ROOT_PATH, 'public/assets/webpack'),
    publicPath: '/assets/webpack/',
    filename: IS_PRODUCTION ? '[name].[chunkhash:8].bundle.js' : '[name].bundle.js',
    chunkFilename: IS_PRODUCTION ? '[name].[chunkhash:8].chunk.js' : '[name].chunk.js',
    globalObject: 'this', // allow HMR and web workers to play nice
  },

  resolve: {
    extensions: ['.js', '.gql', '.graphql'],
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
        test: /\.js$/,
        exclude: path => /node_modules|vendor[\\/]assets/.test(path) && !/\.vue\.js/.test(path),
        loader: 'babel-loader',
        options: {
          cacheDirectory: path.join(CACHE_PATH, 'babel-loader'),
        },
      },
      {
        test: /\.vue$/,
        loader: 'vue-loader',
        options: {
          cacheDirectory: path.join(CACHE_PATH, 'vue-loader'),
          cacheIdentifier: [
            process.env.NODE_ENV || 'development',
            webpack.version,
            VUE_VERSION,
            VUE_LOADER_VERSION,
          ].join('|'),
        },
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
          name: '[name].[hash:8].[ext]',
        },
      },
      {
        test: /\.svg$/,
        exclude: /icons\.svg$/,
        loader: 'raw-loader',
      },
      {
        test: /\.(gif|png)$/,
        loader: 'url-loader',
        options: { limit: 2048 },
      },
      {
        test: /\_worker\.js$/,
        use: [
          {
            loader: 'worker-loader',
            options: {
              name: '[name].[hash:8].worker.js',
              inline: IS_DEV_SERVER,
            },
          },
          'babel-loader',
        ],
      },
      {
        test: /\.(worker(\.min)?\.js|pdf|bmpr)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
        options: {
          name: '[name].[hash:8].[ext]',
        },
      },
      {
        test: /.css$/,
        use: [
          'vue-style-loader',
          {
            loader: 'css-loader',
            options: {
              name: '[name].[hash:8].[ext]',
            },
          },
        ],
      },
      {
        test: /\.(eot|ttf|woff|woff2)$/,
        include: /node_modules\/katex\/dist\/fonts/,
        loader: 'file-loader',
        options: {
          name: '[name].[hash:8].[ext]',
        },
      },
    ],
  },

  optimization: {
    runtimeChunk: 'single',
    splitChunks: {
      maxInitialRequests: 4,
      cacheGroups: {
        default: false,
        common: () => ({
          priority: 20,
          name: 'main',
          chunks: 'initial',
          minChunks: autoEntriesCount * 0.9,
        }),
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
      transform: function(data, opts) {
        const stats = opts.compiler.getStats().toJson({
          chunkModules: false,
          source: false,
          chunks: false,
          modules: false,
          assets: true,
        });
        return JSON.stringify(stats, null, 2);
      },
    }),

    // enable vue-loader to use existing loader rules for other module types
    new VueLoaderPlugin(),

    // automatically configure monaco editor web workers
    new MonacoWebpackPlugin(),

    // prevent pikaday from including moment.js
    new webpack.IgnorePlugin(/moment/, /pikaday/),

    // fix legacy jQuery plugins which depend on globals
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
    }),

    new webpack.NormalModuleReplacementPlugin(/^ee_component\/(.*)\.vue/, function(resource) {
      if (Object.keys(module.exports.resolve.alias).indexOf('ee') >= 0) {
        resource.request = resource.request.replace(/^ee_component/, 'ee');
      } else {
        resource.request = path.join(
          ROOT_PATH,
          'app/assets/javascripts/vue_shared/components/empty_component.js',
        );
      }
    }),

    new CopyWebpackPlugin([
      {
        from: path.join(ROOT_PATH, 'node_modules/pdfjs-dist/cmaps/'),
        to: path.join(ROOT_PATH, 'public/assets/webpack/cmaps/'),
      },
      {
        from: path.join(ROOT_PATH, 'node_modules/@sourcegraph/code-host-integration/'),
        to: path.join(ROOT_PATH, 'public/assets/webpack/sourcegraph/'),
        ignore: ['package.json'],
      },
      {
        from: path.join(
          ROOT_PATH,
          'node_modules/@gitlab/visual-review-tools/dist/visual_review_toolbar.js',
        ),
        to: path.join(ROOT_PATH, 'public/assets/webpack'),
      },
    ]),

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
            file => file.indexOf(nodeModulesPath) !== -1,
          );

          // watch for changes to missing node_modules
          if (hasMissingNodeModules) compilation.contextDependencies.add(nodeModulesPath);

          // watch for changes to automatic entrypoints
          watchAutoEntries.forEach(watchPath => compilation.contextDependencies.add(watchPath));

          // report our auto-generated bundle count
          console.log(
            `${autoEntriesCount} entries from '/pages' automatically added to webpack output.`,
          );

          callback();
        });
      },
    },

    // output the in-memory heap size upon compilation and exit
    WEBPACK_MEMORY_TEST && {
      apply(compiler) {
        compiler.hooks.emit.tapAsync('ReportMemoryConsumptionPlugin', (compilation, callback) => {
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
          const toMB = bytes => Math.floor(bytes / 1024 / 1024);

          console.log(`Webpack heap size: ${toMB(memoryUsage)} MB`);

          // exit in case we're running webpack-dev-server
          IS_DEV_SERVER && process.exit();
        });
      },
    },

    // enable HMR only in webpack-dev-server
    DEV_SERVER_LIVERELOAD && new webpack.HotModuleReplacementPlugin(),

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
        },
      }),

    new webpack.DefinePlugin({
      // This one is used to define window.gon.ee and other things properly in tests:
      'process.env.IS_EE': JSON.stringify(IS_EE),
      // This one is used to check against "EE" properly in application code
      IS_EE: IS_EE ? 'window.gon && window.gon.ee' : JSON.stringify(false),
    }),
  ].filter(Boolean),

  devServer: {
    host: DEV_SERVER_HOST,
    port: DEV_SERVER_PORT,
    disableHostCheck: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
    },
    stats: 'errors-only',
    hot: DEV_SERVER_LIVERELOAD,
    inline: DEV_SERVER_LIVERELOAD,
  },

  devtool: NO_SOURCEMAPS ? false : devtool,

  node: {
    fs: 'empty', // sqljs requires fs
    setImmediate: false,
  },
};
