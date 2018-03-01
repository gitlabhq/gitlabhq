'use strict';

var crypto = require('crypto');
var fs = require('fs');
var path = require('path');
var glob = require('glob');
var webpack = require('webpack');
var StatsWriterPlugin = require('webpack-stats-plugin').StatsWriterPlugin;
var CopyWebpackPlugin = require('copy-webpack-plugin');
var CompressionPlugin = require('compression-webpack-plugin');
var NameAllModulesPlugin = require('name-all-modules-plugin');
var BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;
var WatchMissingNodeModulesPlugin = require('react-dev-utils/WatchMissingNodeModulesPlugin');

var ROOT_PATH = path.resolve(__dirname, '..');
var IS_PRODUCTION = process.env.NODE_ENV === 'production';
var IS_DEV_SERVER = process.argv.join(' ').indexOf('webpack-dev-server') !== -1;
var DEV_SERVER_HOST = process.env.DEV_SERVER_HOST || 'localhost';
var DEV_SERVER_PORT = parseInt(process.env.DEV_SERVER_PORT, 10) || 3808;
var DEV_SERVER_LIVERELOAD = process.env.DEV_SERVER_LIVERELOAD !== 'false';
var WEBPACK_REPORT = process.env.WEBPACK_REPORT;
var NO_COMPRESSION = process.env.NO_COMPRESSION;

var autoEntriesCount = 0;
var watchAutoEntries = [];

function generateEntries() {
  // generate automatic entry points
  var autoEntries = {};
  var pageEntries = glob.sync('pages/**/index.js', { cwd: path.join(ROOT_PATH, 'app/assets/javascripts') });
  watchAutoEntries = [
    path.join(ROOT_PATH, 'app/assets/javascripts/pages/'),
  ];

  function generateAutoEntries(path, prefix = '.') {
    const chunkPath = path.replace(/\/index\.js$/, '');
    const chunkName = chunkPath.replace(/\//g, '.');
    autoEntries[chunkName] = `${prefix}/${path}`;
  }

  pageEntries.forEach(( path ) => generateAutoEntries(path));

  // EE-specific auto entries
  const eePageEntries = glob.sync('pages/**/index.js', { cwd: path.join(ROOT_PATH, 'ee/app/assets/javascripts') });
  eePageEntries.forEach(( path ) => generateAutoEntries(path, 'ee'));
  watchAutoEntries.concat(path.join(ROOT_PATH, 'ee/app/assets/javascripts/pages/'));

  autoEntriesCount = Object.keys(autoEntries).length;

  const manualEntries = {
    balsamiq_viewer:      './blob/balsamiq_viewer.js',
    filtered_search:      './filtered_search/filtered_search_bundle.js',
    help:                 './help/help.js',
    monitoring:           './monitoring/monitoring_bundle.js',
    mr_notes:             './mr_notes/index.js',
    notebook_viewer:      './blob/notebook_viewer.js',
    pdf_viewer:           './blob/pdf_viewer.js',
    project_import_gl:    './projects/project_import_gitlab_project.js',
    protected_branches:   './protected_branches',
    registry_list:        './registry/index.js',
    sketch_viewer:        './blob/sketch_viewer.js',
    stl_viewer:           './blob/stl_viewer.js',
    terminal:             './terminal/terminal_bundle.js',
    ui_development_kit:   './ui_development_kit.js',
    two_factor_auth:      './two_factor_auth.js',

    common:               './commons/index.js',
    common_vue:           './vue_shared/vue_resource_interceptor.js',
    locale:               './locale/index.js',
    main:                 './main.js',
    ide:                  './ide/index.js',
    raven:                './raven/index.js',
    test:                 './test.js',
    u2f:                  ['vendor/u2f'],
    webpack_runtime:      './webpack.js',

    // EE-only
    add_gitlab_slack_application: 'ee/add_gitlab_slack_application/index.js',
    burndown_chart:       'ee/burndown_chart/index.js',
    epic_show:            'ee/epics/epic_show/epic_show_bundle.js',
    new_epic:             'ee/epics/new_epic/new_epic_bundle.js',
    geo_nodes:            'ee/geo_nodes',
    issuable:             'ee/issuable/issuable_bundle.js',
    issues:               'ee/issues/issues_bundle.js',
    ldap_group_links:     'ee/groups/ldap_group_links.js',
    mirrors:              'ee/mirrors',
    ee_protected_branches: 'ee/protected_branches',
    service_desk:         'ee/projects/settings_service_desk/service_desk_bundle.js',
    service_desk_issues:  'ee/service_desk_issues/index.js',
    roadmap:              'ee/roadmap',
  };

  return Object.assign(manualEntries, autoEntries);
}

var config = {
  context: path.join(ROOT_PATH, 'app/assets/javascripts'),

  entry: generateEntries,

  output: {
    path: path.join(ROOT_PATH, 'public/assets/webpack'),
    publicPath: '/assets/webpack/',
    filename: IS_PRODUCTION ? '[name].[chunkhash].bundle.js' : '[name].bundle.js',
    chunkFilename: IS_PRODUCTION ? '[name].[chunkhash].chunk.js' : '[name].chunk.js',
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|vendor\/assets)/,
        loader: 'babel-loader',
      },
      {
        test: /\.vue$/,
        loader: 'vue-loader',
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
              inline: true
            }
          },
          { loader: 'babel-loader' },
        ],
      },
      {
        test: /\.(worker(\.min)?\.js|pdf|bmpr)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
        options: {
          name: '[name].[hash].[ext]',
        }
      },
      {
        test: /katex.css$/,
        include: /node_modules\/katex\/dist/,
        use: [
          { loader: 'style-loader' },
          {
            loader: 'css-loader',
            options: {
              name: '[name].[hash].[ext]'
            }
          },
        ],
      },
      {
        test: /\.(eot|ttf|woff|woff2)$/,
        include: /node_modules\/katex\/dist\/fonts/,
        loader: 'file-loader',
        options: {
          name: '[name].[hash].[ext]',
        }
      },
      {
        test: /monaco-editor\/\w+\/vs\/loader\.js$/,
        use: [
          { loader: 'exports-loader', options: 'l.global' },
          { loader: 'imports-loader', options: 'l=>{},this=>l,AMDLoader=>this,module=>undefined' },
        ],
      }
    ],

    noParse: [/monaco-editor\/\w+\/vs\//],
    strictExportPresence: true,
  },

  plugins: [
    // manifest filename must match config.webpack.manifest_filename
    // webpack-rails only needs assetsByChunkName to function properly
    new StatsWriterPlugin({
      filename: 'manifest.json',
      transform: function(data, opts) {
        var stats = opts.compiler.getStats().toJson({
          chunkModules: false,
          source: false,
          chunks: false,
          modules: false,
          assets: true
        });
        return JSON.stringify(stats, null, 2);
      }
    }),

    // prevent pikaday from including moment.js
    new webpack.IgnorePlugin(/moment/, /pikaday/),

    // fix legacy jQuery plugins which depend on globals
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
    }),

    // assign deterministic module ids
    new webpack.NamedModulesPlugin(),
    new NameAllModulesPlugin(),

    // assign deterministic chunk ids
    new webpack.NamedChunksPlugin((chunk) => {
      if (chunk.name) {
        return chunk.name;
      }

      const moduleNames = [];

      function collectModuleNames(m) {
        // handle ConcatenatedModule which does not have resource nor context set
        if (m.modules) {
          m.modules.forEach(collectModuleNames);
          return;
        }

        const pagesBase = path.join(ROOT_PATH, 'app/assets/javascripts/pages');

        if (m.resource.indexOf(pagesBase) === 0) {
          moduleNames.push(path.relative(pagesBase, m.resource)
            .replace(/\/index\.[a-z]+$/, '')
            .replace(/\//g, '__'));
        } else {
          moduleNames.push(path.relative(m.context, m.resource));
        }
      }

      chunk.forEachModule(collectModuleNames);

      const hash = crypto.createHash('sha256')
        .update(moduleNames.join('_'))
        .digest('hex');

      return `${moduleNames[0]}-${hash.substr(0, 6)}`;
    }),

    // create cacheable common library bundle for all vue chunks
    new webpack.optimize.CommonsChunkPlugin({
      name: 'common_vue',
      chunks: [
        'boards',
        'deploy_keys',
        'environments',
        'filtered_search',
        'groups',
        'monitoring',
        'mr_notes',
        'notebook_viewer',
        'pdf_viewer',
        'pipelines',
        'pipelines_details',
        'registry_list',
        'ide',
        'schedule_form',
        'schedules_index',
        'sidebar',
        'vue_merge_request_widget',
      ],
      minChunks: function(module, count) {
        return module.resource && (/vue_shared/).test(module.resource);
      },
    }),

    // create cacheable common library bundles
    new webpack.optimize.CommonsChunkPlugin({
      names: ['main', 'common', 'webpack_runtime'],
    }),

    // enable scope hoisting
    new webpack.optimize.ModuleConcatenationPlugin(),

    // copy pre-compiled vendor libraries verbatim
    new CopyWebpackPlugin([
      {
        from: path.join(ROOT_PATH, `node_modules/monaco-editor/${IS_PRODUCTION ? 'min' : 'dev'}/vs`),
        to: 'monaco-editor/vs',
        transform: function(content, path) {
          if (/\.js$/.test(path) && !/worker/i.test(path) && !/typescript/i.test(path)) {
            return (
              '(function(){\n' +
              'var define = this.define, require = this.require;\n' +
              'window.define = define; window.require = require;\n' +
              content +
              '\n}.call(window.__monaco_context__ || (window.__monaco_context__ = {})));'
            );
          }
          return content;
        }
      }
    ]),
  ],

  resolve: {
    extensions: ['.js'],
    alias: {
      '~':              path.join(ROOT_PATH, 'app/assets/javascripts'),
      'emojis':         path.join(ROOT_PATH, 'fixtures/emojis'),
      'empty_states':   path.join(ROOT_PATH, 'app/views/shared/empty_states'),
      'icons':          path.join(ROOT_PATH, 'app/views/shared/icons'),
      'images':         path.join(ROOT_PATH, 'app/assets/images'),
      'vendor':         path.join(ROOT_PATH, 'vendor/assets/javascripts'),
      'vue$':           'vue/dist/vue.esm.js',
      'spec':           path.join(ROOT_PATH, 'spec/javascripts'),

      // EE-only
      'ee':              path.join(ROOT_PATH, 'ee/app/assets/javascripts'),
      'ee_empty_states': path.join(ROOT_PATH, 'ee/app/views/shared/empty_states'),
      'ee_icons':        path.join(ROOT_PATH, 'ee/app/views/shared/icons'),
      'ee_images':       path.join(ROOT_PATH, 'ee/app/assets/images'),
    }
  },

  // sqljs requires fs
  node: {
    fs: 'empty',
  },
};

if (IS_PRODUCTION) {
  config.devtool = 'source-map';
  config.plugins.push(
    new webpack.NoEmitOnErrorsPlugin(),
    new webpack.LoaderOptionsPlugin({
      minimize: true,
      debug: false
    }),
    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true
    }),
    new webpack.DefinePlugin({
      'process.env': { NODE_ENV: JSON.stringify('production') }
    })
  );

  // compression can require a lot of compute time and is disabled in CI
  if (!NO_COMPRESSION) {
    config.plugins.push(new CompressionPlugin());
  }
}

if (IS_DEV_SERVER) {
  config.devtool = 'cheap-module-eval-source-map';
  config.devServer = {
    host: DEV_SERVER_HOST,
    port: DEV_SERVER_PORT,
    disableHostCheck: true,
    headers: { 'Access-Control-Allow-Origin': '*' },
    stats: 'errors-only',
    hot: DEV_SERVER_LIVERELOAD,
    inline: DEV_SERVER_LIVERELOAD
  };
  config.plugins.push(
    // watch node_modules for changes if we encounter a missing module compile error
    new WatchMissingNodeModulesPlugin(path.join(ROOT_PATH, 'node_modules')),

    // watch for changes to our automatic entry point modules
    {
      apply(compiler) {
        compiler.plugin('emit', (compilation, callback) => {
          compilation.contextDependencies = [
            ...compilation.contextDependencies,
            ...watchAutoEntries,
          ];

          // report our auto-generated bundle count
          console.log(`${autoEntriesCount} entries from '/pages' automatically added to webpack output.`);

          callback();
        })
      },
    }
  );
  if (DEV_SERVER_LIVERELOAD) {
    config.plugins.push(new webpack.HotModuleReplacementPlugin());
  }
}

if (WEBPACK_REPORT) {
  config.plugins.push(
    new BundleAnalyzerPlugin({
      analyzerMode: 'static',
      generateStatsFile: true,
      openAnalyzer: false,
      reportFilename: path.join(ROOT_PATH, 'webpack-report/index.html'),
      statsFilename: path.join(ROOT_PATH, 'webpack-report/stats.json'),
    })
  );
}

module.exports = config;
