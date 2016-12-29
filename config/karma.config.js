var path = require('path');
var webpackConfig = require('./webpack.config.js');
var ROOT_PATH = path.resolve(__dirname, '..');

// Karma configuration
module.exports = function(config) {
  config.set({
    basePath: ROOT_PATH,
    frameworks: ['jquery-2.1.0', 'jasmine'],
    files: [
      'spec/javascripts/*_spec.js',
      'spec/javascripts/*_spec.js.es6',
      { pattern: 'spec/javascripts/fixtures/**/*.html', included: false, served: true },
      { pattern: 'spec/javascripts/fixtures/**/*.json', included: false, served: true },
    ],
    preprocessors: {
      'spec/javascripts/*_spec.js': ['webpack'],
      'spec/javascripts/*_spec.js.es6': ['webpack'],
      'app/assets/javascripts/**/*.js': ['webpack'],
      'app/assets/javascripts/**/*.js.es6': ['webpack'],
    },

    webpack: webpackConfig,

    webpackMiddleware: { stats: 'errors-only' },
  });
};
