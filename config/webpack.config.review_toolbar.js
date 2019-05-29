const path = require('path');
const CompressionPlugin = require('compression-webpack-plugin');

const ROOT_PATH = path.resolve(__dirname, '..');
const CACHE_PATH = process.env.WEBPACK_CACHE_PATH || path.join(ROOT_PATH, 'tmp/cache');
const NO_SOURCEMAPS = process.env.NO_SOURCEMAPS;
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

const devtool = IS_PRODUCTION ? 'source-map' : 'cheap-module-eval-source-map';

const alias = {
  vendor: path.join(ROOT_PATH, 'vendor/assets/javascripts'),
  spec: path.join(ROOT_PATH, 'spec/javascripts'),
};

module.exports = {
  mode: IS_PRODUCTION ? 'production' : 'development',

  context: path.join(ROOT_PATH, 'app/assets/javascripts'),

  name: 'visual_review_toolbar',

  entry: './visual_review_toolbar',

  output: {
    path: path.join(ROOT_PATH, 'public/assets/webpack'),
    filename: 'visual_review_toolbar.js',
    library: 'VisualReviewToolbar',
    libraryTarget: 'var',
  },

  resolve: {
    alias,
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        loader: 'babel-loader',
        options: {
          cacheDirectory: path.join(CACHE_PATH, 'babel-loader'),
        },
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },

  plugins: [
    // compression can require a lot of compute time and is disabled in CI
    new CompressionPlugin(),
  ].filter(Boolean),

  devtool: NO_SOURCEMAPS ? false : devtool,
};
