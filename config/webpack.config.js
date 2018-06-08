const fs = require('fs');
const path = require('path');
const glob = require('glob');
const webpack = require('webpack');
const VueLoaderPlugin = require('vue-loader/lib/plugin');
const StatsWriterPlugin = require('webpack-stats-plugin').StatsWriterPlugin;
const CompressionPlugin = require('compression-webpack-plugin');
const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

const ROOT_PATH = path.resolve(__dirname, '..');
const CACHE_PATH = path.join(ROOT_PATH, 'tmp/cache');
const IS_PRODUCTION = process.env.NODE_ENV === 'production';
const IS_DEV_SERVER = process.argv.join(' ').indexOf('webpack-dev-server') !== -1;
const DEV_SERVER_HOST = process.env.DEV_SERVER_HOST || 'localhost';
const DEV_SERVER_PORT = parseInt(process.env.DEV_SERVER_PORT, 10) || 3808;
const DEV_SERVER_LIVERELOAD = IS_DEV_SERVER && process.env.DEV_SERVER_LIVERELOAD !== 'false';
const WEBPACK_REPORT = process.env.WEBPACK_REPORT;
const NO_COMPRESSION = process.env.NO_COMPRESSION;

const VUE_VERSION = require('vue/package.json').version;
const VUE_LOADER_VERSION = require('vue-loader/package.json').version;

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

  // EE-specific auto entries
  const eePageEntries = glob.sync('pages/**/index.js', {
    cwd: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
  });
  eePageEntries.forEach(path => generateAutoEntries(path, 'ee'));
  watchAutoEntries.push(path.join(ROOT_PATH, 'ee/app/assets/javascripts/pages/'));

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
    raven: './raven/index.js',
  };

  return Object.assign(manualEntries, autoEntries);
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
    extensions: ['.js'],
    alias: {
      '~': path.join(ROOT_PATH, 'app/assets/javascripts'),
      emojis: path.join(ROOT_PATH, 'fixtures/emojis'),
      empty_states: path.join(ROOT_PATH, 'app/views/shared/empty_states'),
      icons: path.join(ROOT_PATH, 'app/views/shared/icons'),
      images: path.join(ROOT_PATH, 'app/assets/images'),
      vendor: path.join(ROOT_PATH, 'vendor/assets/javascripts'),
      vue$: 'vue/dist/vue.esm.js',
      spec: path.join(ROOT_PATH, 'spec/javascripts'),

      // EE-only
      ee: path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
      ee_empty_states: path.join(ROOT_PATH, 'ee/app/views/shared/empty_states'),
      ee_icons: path.join(ROOT_PATH, 'ee/app/views/shared/icons'),
      ee_images: path.join(ROOT_PATH, 'ee/app/assets/images'),
    },
  },

  module: {
    strictExportPresence: true,
    rules: [
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
        test: /\.svg$/,
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
    nodeEnv: false,
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
            file => file.indexOf(nodeModulesPath) !== -1
          );

          // watch for changes to missing node_modules
          if (hasMissingNodeModules) compilation.contextDependencies.add(nodeModulesPath);

          // watch for changes to automatic entrypoints
          watchAutoEntries.forEach(watchPath => compilation.contextDependencies.add(watchPath));

          // report our auto-generated bundle count
          console.log(
            `${autoEntriesCount} entries from '/pages' automatically added to webpack output.`
          );

          callback();
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

  devtool: IS_PRODUCTION ? 'source-map' : 'cheap-module-eval-source-map',

  // sqljs requires fs
  node: { fs: 'empty' },
};
