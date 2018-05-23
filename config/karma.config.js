const path = require('path');
const glob = require('glob');
const chalk = require('chalk');
const webpack = require('webpack');
const argumentsParser = require('commander');
const webpackConfig = require('./webpack.config.js');

const ROOT_PATH = path.resolve(__dirname, '..');

function fatalError(message) {
  console.error(chalk.red(`\nError: ${message}\n`));
  process.exit(1);
}

// disable problematic options
webpackConfig.entry = undefined;
webpackConfig.mode = 'development';
webpackConfig.optimization.runtimeChunk = false;
webpackConfig.optimization.splitChunks = false;

// use quicker sourcemap option
webpackConfig.devtool = 'cheap-inline-source-map';

const specFilters = argumentsParser
  .option(
    '-f, --filter-spec [filter]',
    'Filter run spec files by path. Multiple filters are like a logical OR.',
    (filter, memo) => {
      memo.push(filter, filter.replace(/\/?$/, '/**/*.js'));
      return memo;
    },
    []
  )
  .parse(process.argv).filterSpec;

if (specFilters.length) {
  const specsPath = /^(?:\.[\\\/])?spec[\\\/]javascripts[\\\/]/;

  // resolve filters
  let filteredSpecFiles = specFilters.map(filter =>
    glob
      .sync(filter, {
        root: ROOT_PATH,
        matchBase: true,
      })
      .filter(path => path.endsWith('spec.js'))
  );

  // flatten
  filteredSpecFiles = Array.prototype.concat.apply([], filteredSpecFiles);

  // remove duplicates
  filteredSpecFiles = [...new Set(filteredSpecFiles)];

  if (filteredSpecFiles.length < 1) {
    fatalError('Your filter did not match any test files.');
  }

  if (!filteredSpecFiles.every(file => specsPath.test(file))) {
    fatalError('Test files must be located within /spec/javascripts.');
  }

  const newContext = filteredSpecFiles.reduce((context, file) => {
    const relativePath = file.replace(specsPath, '');
    context[file] = `./${relativePath}`;
    return context;
  }, {});

  webpackConfig.plugins.push(
    new webpack.ContextReplacementPlugin(
      /spec[\\\/]javascripts$/,
      path.join(ROOT_PATH, 'spec/javascripts'),
      newContext
    )
  );
}

// Karma configuration
module.exports = function(config) {
  process.env.TZ = 'Etc/UTC';

  const progressReporter = process.env.CI ? 'mocha' : 'progress';

  const karmaConfig = {
    basePath: ROOT_PATH,
    browsers: ['ChromeHeadlessCustom'],
    customLaunchers: {
      ChromeHeadlessCustom: {
        base: 'ChromeHeadless',
        displayName: 'Chrome',
        flags: [
          // chrome cannot run in sandboxed mode inside a docker container unless it is run with
          // escalated kernel privileges (e.g. docker run --cap-add=CAP_SYS_ADMIN)
          '--no-sandbox',
        ],
      },
    },
    frameworks: ['jasmine'],
    files: [
      { pattern: 'spec/javascripts/test_bundle.js', watched: false },
      { pattern: 'spec/javascripts/fixtures/**/*@(.json|.html|.html.raw|.png)', included: false },
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
      fixWebpackSourcePaths: true,
    };
    karmaConfig.browserNoActivityTimeout = 60000; // 60 seconds
  }

  if (process.env.DEBUG) {
    karmaConfig.logLevel = config.LOG_DEBUG;
    process.env.CHROME_LOG_FILE = process.env.CHROME_LOG_FILE || 'chrome_debug.log';
  }

  if (process.env.CHROME_LOG_FILE) {
    karmaConfig.customLaunchers.ChromeHeadlessCustom.flags.push('--enable-logging', '--v=1');
  }

  config.set(karmaConfig);
};
