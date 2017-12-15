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
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|vendor\/assets)/,
        loader: 'babel-loader',
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
    // fix legacy jQuery plugins which depend on globals
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
    }),

    // assign deterministic module ids
    new webpack.NamedModulesPlugin(),
    new NameAllModulesPlugin(),
  ],

  resolve: {
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

module.exports = config;
