'use strict';

var fs = require('fs');
var path = require('path');
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

var config = {
  // because sqljs requires fs.
  node: {
    fs: "empty"
  },
  context: path.join(ROOT_PATH, 'app/assets/javascripts'),
  entry: {
    account:              './profile/account/index.js',
    balsamiq_viewer:      './blob/balsamiq_viewer.js',
    blob:                 './blob_edit/blob_bundle.js',
    boards:               './boards/boards_bundle.js',
    common:               './commons/index.js',
    common_vue:           './vue_shared/vue_resource_interceptor.js',
    cycle_analytics:      './cycle_analytics/cycle_analytics_bundle.js',
    commit_pipelines:     './commit/pipelines/pipelines_bundle.js',
    deploy_keys:          './deploy_keys/index.js',
    docs:                 './docs/docs_bundle.js',
    diff_notes:           './diff_notes/diff_notes_bundle.js',
    environments:         './environments/environments_bundle.js',
    environments_folder:  './environments/folder/environments_folder_bundle.js',
    filtered_search:      './filtered_search/filtered_search_bundle.js',
    graphs:               './graphs/graphs_bundle.js',
    graphs_charts:        './graphs/graphs_charts.js',
    graphs_show:          './graphs/graphs_show.js',
    group:                './group.js',
    groups:               './groups/index.js',
    groups_list:          './groups_list.js',
    help:                 './help/help.js',
    how_to_merge:         './how_to_merge.js',
    issue_show:           './issue_show/index.js',
    integrations:         './integrations',
    job_details:          './jobs/job_details_bundle.js',
    locale:               './locale/index.js',
    main:                 './main.js',
    merge_conflicts:      './merge_conflicts/merge_conflicts_bundle.js',
    monitoring:           './monitoring/monitoring_bundle.js',
    network:              './network/network_bundle.js',
    notebook_viewer:      './blob/notebook_viewer.js',
    notes:                './notes/index.js',
    pdf_viewer:           './blob/pdf_viewer.js',
    pipelines:            './pipelines/pipelines_bundle.js',
    pipelines_charts:     './pipelines/pipelines_charts.js',
    pipelines_details:    './pipelines/pipeline_details_bundle.js',
    pipelines_times:      './pipelines/pipelines_times.js',
    profile:              './profile/profile_bundle.js',
    project_import_gl:    './projects/project_import_gitlab_project.js',
    project_new:          './projects/project_new.js',
    prometheus_metrics:   './prometheus_metrics',
    protected_branches:   './protected_branches',
    protected_tags:       './protected_tags',
    registry_list:        './registry/index.js',
    ide:                 './ide/index.js',
    sidebar:              './sidebar/sidebar_bundle.js',
    schedule_form:        './pipeline_schedules/pipeline_schedule_form_bundle.js',
    schedules_index:      './pipeline_schedules/pipeline_schedules_index_bundle.js',
    snippet:              './snippet/snippet_bundle.js',
    sketch_viewer:        './blob/sketch_viewer.js',
    stl_viewer:           './blob/stl_viewer.js',
    terminal:             './terminal/terminal_bundle.js',
    u2f:                  ['vendor/u2f'],
    ui_development_kit:   './ui_development_kit.js',
    raven:                './raven/index.js',
    vue_merge_request_widget: './vue_merge_request_widget/index.js',
    test:                 './test.js',
    two_factor_auth:      './two_factor_auth.js',
    users:                './users/index.js',
    performance_bar:      './performance_bar.js',
    webpack_runtime:      './webpack.js',
  },

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
      return chunk.mapModules((m) => {
        const pagesBase = path.join(ROOT_PATH, 'app/assets/javascripts/pages');
        if (m.resource.indexOf(pagesBase) === 0) {
          return path.relative(pagesBase, m.resource)
            .replace(/\/index\.[a-z]+$/, '')
            .replace(/\//g, '__');
        }
        return path.relative(m.context, m.resource);
      }).join('_');
    }),

    // create cacheable common library bundle for all vue chunks
    new webpack.optimize.CommonsChunkPlugin({
      name: 'common_vue',
      chunks: [
        'boards',
        'commit_pipelines',
        'cycle_analytics',
        'deploy_keys',
        'diff_notes',
        'environments',
        'environments_folder',
        'filtered_search',
        'groups',
        'issue_show',
        'job_details',
        'merge_conflicts',
        'monitoring',
        'notebook_viewer',
        'notes',
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

    // create cacheable common library bundle for all d3 chunks
    new webpack.optimize.CommonsChunkPlugin({
      name: 'common_d3',
      chunks: [
        'graphs',
        'graphs_show',
        'monitoring',
        'users',
      ],
      minChunks: function (module, count) {
        return module.resource && /d3-/.test(module.resource);
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
    }
  }
}

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
    new WatchMissingNodeModulesPlugin(path.join(ROOT_PATH, 'node_modules'))
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
