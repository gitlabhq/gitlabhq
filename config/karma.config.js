var path = require('path');
var webpack = require('webpack');
var webpackConfig = require('./webpack.config.js');
var ROOT_PATH = path.resolve(__dirname, '..');

// add coverage instrumentation to babel config
if (webpackConfig.module && webpackConfig.module.rules) {
  var babelConfig = webpackConfig.module.rules.find(function (rule) {
    return rule.loader === 'babel-loader';
  });

  babelConfig.options = babelConfig.options || {};
  babelConfig.options.plugins = babelConfig.options.plugins || [];
  babelConfig.options.plugins.push('istanbul');
}

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
  config.set({
    basePath: ROOT_PATH,
    browsers: ['PhantomJS'],
    frameworks: ['jasmine'],
    files: [
      { pattern: 'spec/javascripts/test_bundle.js', watched: false },
      { pattern: 'spec/javascripts/fixtures/**/*@(.json|.html|.html.raw)', included: false },
    ],
    preprocessors: {
      'spec/javascripts/**/*.js': ['webpack', 'sourcemap'],
    },
    reporters: [progressReporter, 'coverage-istanbul'],
    coverageIstanbulReporter: {
      reports: ['html', 'text-summary'],
      dir: 'coverage-javascript/',
      subdir: '.',
      fixWebpackSourcePaths: true
    },
    webpack: webpackConfig,
    webpackMiddleware: { stats: 'errors-only' },
  });
};
