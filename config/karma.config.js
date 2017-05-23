var path = require('path');
var webpack = require('webpack');
var webpackConfig = require('./webpack.config.js');
var ROOT_PATH = path.resolve(__dirname, '..');

// remove problematic plugins
if (webpackConfig.plugins) {
  webpackConfig.plugins = webpackConfig.plugins.filter(function (plugin) {
    return !(
      plugin instanceof webpack.optimize.CommonsChunkPlugin ||
      plugin instanceof webpack.DefinePlugin
    );
  });
}

// Karma configuration
module.exports = function(config) {
  var progressReporter = process.env.CI ? 'mocha' : 'progress';

  var karmaConfig = {
    basePath: ROOT_PATH,
    browsers: [
      'PhantomJS',
      'Chrome',
      'Firefox',
      'IE',
      'Edge',
    ],
    frameworks: ['jasmine'],
    files: [
      { pattern: 'spec/javascripts/test_bundle.js', watched: false },
      { pattern: 'spec/javascripts/fixtures/**/*@(.json|.html|.html.raw)', included: false },
    ],
    preprocessors: {
      'spec/javascripts/**/*.js': ['webpack', 'sourcemap'],
    },
    reporters: [progressReporter],
    webpack: webpackConfig,
    webpackMiddleware: { stats: 'errors-only' },
  };

  if (process.env.BABEL_ENV === 'coverage' || process.env.NODE_ENV === 'coverage') {
    karmaConfig.reporters.push('coverage-istanbul');
    karmaConfig.coverageIstanbulReporter = {
      reports: ['html', 'text-summary'],
      dir: 'coverage-javascript/',
      subdir: '.',
      fixWebpackSourcePaths: true
    };
  }

  config.set(karmaConfig);
};
