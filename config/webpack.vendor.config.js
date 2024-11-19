const path = require('path');
const webpack = require('webpack');
const { YarnCheck } = require('yarn-check-webpack-plugin');
const { resolutions } = require('../package.json');
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
      '@apollo/client/core',
      '@gitlab/at.js',
      'core-js',
      'dexie',
      'dompurify',
      'echarts',
      'jed',
      'jquery/dist/jquery.slim.js',
      'katex',
      'lodash',
      'mousetrap',
      'pikaday',
      'popper.js',
      'sortablejs/modular/sortable.esm.js',
      'source-map',
      'three',
      'vue',
      'vuex',
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
          @gitlab/noop is a tool to remove parts of our dependency tree. By it's
          nature it might not be installed into a folder itself and that would
          confuse this webpack plugin
          */
          '@gitlab/noop',
          /**
           * This Webpack plugin complains when packages have the wrong versions.
           * It doesn't seem like it considers yarn resolutions, so we just do it
           * with this manually
           */
          ...Object.keys(resolutions).map((name) => name.split('/').reverse()[0]),
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
