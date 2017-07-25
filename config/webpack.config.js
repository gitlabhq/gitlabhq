'use strict';

var fs = require('fs');
var path = require('path');
var webpack = require('webpack');
var StatsPlugin = require('stats-webpack-plugin');
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
    balsamiq_viewer:      './blob/balsamiq_viewer.js',
    blob:                 './blob_edit/blob_bundle.js',
    boards:               './boards/boards_bundle.js',
    burndown_chart:       './burndown_chart/index.js',
    common:               './commons/index.js',
    common_vue:           ['vue', './vue_shared/common_vue.js'],
    common_d3:            ['d3'],
    cycle_analytics:      './cycle_analytics/cycle_analytics_bundle.js',
    commit_pipelines:     './commit/pipelines/pipelines_bundle.js',
    deploy_keys:          './deploy_keys/index.js',
    diff_notes:           './diff_notes/diff_notes_bundle.js',
    environments:         './environments/environments_bundle.js',
    environments_folder:  './environments/folder/environments_folder_bundle.js',
    filtered_search:      './filtered_search/filtered_search_bundle.js',
    graphs:               './graphs/graphs_bundle.js',
    group:                './group.js',
    groups:               './groups/index.js',
    groups_list:          './groups_list.js',
    issuable:             './issuable/issuable_bundle.js',
    issues:               './issues/issues_bundle.js',
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
    pdf_viewer:           './blob/pdf_viewer.js',
    pipelines:            './pipelines/pipelines_bundle.js',
    pipelines_details:     './pipelines/pipeline_details_bundle.js',
    profile:              './profile/profile_bundle.js',
    prometheus_metrics:   './prometheus_metrics',
    protected_branches:   './protected_branches',
    ee_protected_branches: './protected_branches/ee',
    protected_tags:       './protected_tags',
    ee_protected_tags:    './protected_tags/ee',
    service_desk:         './projects/settings_service_desk/service_desk_bundle.js',
    sidebar:              './sidebar/sidebar_bundle.js',
    schedule_form:        './pipeline_schedules/pipeline_schedule_form_bundle.js',
    schedules_index:      './pipeline_schedules/pipeline_schedules_index_bundle.js',
    snippet:              './snippet/snippet_bundle.js',
    sketch_viewer:        './blob/sketch_viewer.js',
    stl_viewer:           './blob/stl_viewer.js',
    terminal:             './terminal/terminal_bundle.js',
    u2f:                  ['vendor/u2f'],
    users:                './users/index.js',
    raven:                './raven/index.js',
    vue_merge_request_widget: './vue_merge_request_widget/index.js',
    test:                 './test.js',
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
        test: /\.(worker\.js|pdf|bmpr)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
      },
      {
        test: /locale\/\w+\/(.*)\.js$/,
        loader: 'exports-loader?locales',
      },
    ]
  },

  plugins: [
    // manifest filename must match config.webpack.manifest_filename
    // webpack-rails only needs assetsByChunkName to function properly
    new StatsPlugin('manifest.json', {
      chunkModules: false,
      source: false,
      chunks: false,
      modules: false,
      assets: true
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
      return chunk.modules.map((m) => {
        var chunkPath = m.request.split('!').pop();
        return path.relative(m.context, chunkPath);
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
        'issuable',
        'issue_show',
        'job_details',
        'merge_conflicts',
        'monitoring',
        'notebook_viewer',
        'pdf_viewer',
        'pipelines',
        'pipelines_details',
        'schedule_form',
        'schedules_index',
        'service_desk',
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
        'users',
        'monitoring',
        'burndown_chart',
      ],
    }),

    // create cacheable common library bundles
    new webpack.optimize.CommonsChunkPlugin({
      names: ['main', 'locale', 'common', 'webpack_runtime'],
    }),
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

  // zopfli requires a lot of compute time and is disabled in CI
  if (!NO_COMPRESSION) {
    // gracefully fall back to gzip if `node-zopfli` is unavailable (e.g. in CentOS 6)
    try {
      config.plugins.push(new CompressionPlugin({ algorithm: 'zopfli' }));
    } catch(err) {
      config.plugins.push(new CompressionPlugin({ algorithm: 'gzip' }));
    }
  }
}

if (IS_DEV_SERVER) {
  config.devtool = 'cheap-module-eval-source-map';
  config.devServer = {
    host: DEV_SERVER_HOST,
    port: DEV_SERVER_PORT,
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
