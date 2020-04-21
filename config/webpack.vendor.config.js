const path = require('path');
const webpack = require('webpack');
const vendorDllHash = require('./helpers/vendor_dll_hash');
const { YarnCheck } = require('yarn-check-webpack-plugin');

const ROOT_PATH = path.resolve(__dirname, '..');

const dllHash = vendorDllHash();
const dllCachePath = path.join(ROOT_PATH, `tmp/cache/webpack-dlls/${dllHash}`);
const dllPublicPath = `/assets/webpack/dll.${dllHash}/`;

module.exports = {
  mode: 'development',
  resolve: {
    extensions: ['.js'],
  },

  // ensure output is not generated when errors are encountered
  bail: true,

  context: ROOT_PATH,

  entry: {
    vendor: [
      'jquery',
      'pdfjs-dist/build/pdf',
      'pdfjs-dist/build/pdf.worker.min',
      'sql.js',
      'core-js',
      'echarts',
      'lodash',
      'vuex',
      'pikaday',
      'vue/dist/vue.esm.js',
      '@gitlab/at.js',
      'jed',
      'mermaid',
      'katex',
      'three',
      'select2',
      'moment',
      'aws-sdk',
      'sanitize-html',
      'bootstrap/dist/js/bootstrap.js',
      'sortablejs/modular/sortable.esm.js',
      'popper.js',
      'apollo-client',
      'source-map',
      'mousetrap',
    ],
  },

  output: {
    path: dllCachePath,
    publicPath: dllPublicPath,
    filename: '[name].dll.bundle.js',
    chunkFilename: '[name].dll.chunk.js',
    library: '[name]_[hash]',
  },

  plugins: [
    new webpack.DllPlugin({
      path: path.join(dllCachePath, '[name].dll.manifest.json'),
      name: '[name]_[hash]',
    }),
    new YarnCheck({
      rootDirectory: ROOT_PATH,
      exclude: /ts-jest/,
      forceKill: true,
    }),
  ],

  node: {
    fs: 'empty', // sqljs requires fs
    setImmediate: false,
  },

  devtool: 'cheap-module-source-map',
};
