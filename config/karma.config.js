var path = require('path');
var webpackConfig = require('./webpack.config.js');
var ROOT_PATH = path.resolve(__dirname, '..');

// Karma configuration
module.exports = function(config) {
  config.set({
    basePath: ROOT_PATH,
    browsers: ['PhantomJS'],
    frameworks: ['jasmine'],
    files: [
      { pattern: 'spec/javascripts/test_bundle.js', watched: false },
      { pattern: 'spec/javascripts/fixtures/**/*@(.json|.html|.html.raw)', included: false },
    ],
    preprocessors: {
      'spec/javascripts/**/*.js?(.es6)': ['webpack', 'sourcemap'],
    },
    webpack: webpackConfig,
    webpackMiddleware: { stats: 'errors-only' },
  });
};
