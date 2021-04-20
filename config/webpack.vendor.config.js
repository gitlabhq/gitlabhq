const path = require('path');
const webpack = require('webpack');
const { YarnCheck } = require('yarn-check-webpack-plugin');
const vendorDllHash = require('./helpers/vendor_dll_hash');

const ROOT_PATH = path.resolve(__dirname, '..');

const dllHash = vendorDllHash();
const dllCachePath = path.join(ROOT_PATH, `tmp/cache/webpack-dlls/${dllHash}`);
const dllPublicPath = `/assets/webpack/dll.${dllHash}/`;

module.exports = {
  mode: 'development',
  resolve: {
    extensions: ['.js'],
    alias: {
      jquery$: 'jquery/dist/jquery.slim.js',
    },
  },

  // ensure output is not generated when errors are encountered
  bail: true,

  context: ROOT_PATH,

  entry: {
    vendor: [
      'jquery/dist/jquery.slim.js',
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
      'moment-mini',
      'aws-sdk',
      'dompurify',
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
      exclude: new RegExp(
        [
          /*
          chokidar has a newer version which do not depend on fsevents,
          is faster and only compatible with newer node versions (>=8)

          Their actual interface remains the same and we can safely _force_
          newer versions to get performance and security benefits.

          This can be removed once all dependencies are up to date:
          https://gitlab.com/gitlab-org/gitlab/-/issues/219353
          */
          'chokidar',
          // We are ignoring ts-jest, because we force a newer version, compatible with our current jest version
          'ts-jest',
        ].join('|'),
      ),
      forceKill: true,
    }),
  ],

  node: {
    fs: 'empty', // sqljs requires fs
    setImmediate: false,
  },

  devtool: 'cheap-module-source-map',
};
