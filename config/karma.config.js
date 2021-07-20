/* eslint-disable no-inner-declarations, no-param-reassign */
const path = require('path');
const chalk = require('chalk');
const argumentsParser = require('commander');
const glob = require('glob');
const webpack = require('webpack');
const IS_EE = require('./helpers/is_ee_env');
const webpackConfig = require('./webpack.config');

const ROOT_PATH = path.resolve(__dirname, '..');
const SPECS_PATH = /^(?:\.[\\/])?(ee[\\/])?spec[\\/]javascripts[\\/]/;

function exitError(message) {
  console.error(chalk.red(`\nError: ${message}\n`));
  process.exit(1);
}

function exitWarn(message) {
  console.error(chalk.yellow(`\nWarn: ${message}\n`));
  process.exit(0);
}

function exit(message, isError = true) {
  const fn = isError ? exitError : exitWarn;

  fn(message);
}

// disable problematic options
webpackConfig.entry = undefined;
webpackConfig.mode = 'development';
webpackConfig.optimization.nodeEnv = false;
webpackConfig.optimization.runtimeChunk = false;
webpackConfig.optimization.splitChunks = false;

// use quicker sourcemap option
webpackConfig.devtool = 'cheap-inline-source-map';

// set BABEL_ENV to indicate when we're running code coverage
webpackConfig.plugins.push(
  new webpack.DefinePlugin({
    'process.env.BABEL_ENV': JSON.stringify(process.env.BABEL_ENV || process.env.NODE_ENV || null),
  }),
);

const options = argumentsParser
  .option('--no-fail-on-empty-test-suite')
  .option(
    '-f, --filter-spec [filter]',
    'Filter run spec files by path. Multiple filters are like a logical OR.',
    (filter, memo) => {
      memo.push(filter, filter.replace(/\/?$/, '/**/*.js'));
      return memo;
    },
    [],
  )
  .parse(process.argv);

const specFilters = options.filterSpec;

const createContext = (specFiles, regex, suffix) => {
  const newContext = specFiles.reduce((context, file) => {
    const relativePath = file.replace(SPECS_PATH, '');
    context[file] = `./${relativePath}`;
    return context;
  }, {});

  webpackConfig.plugins.push(
    new webpack.ContextReplacementPlugin(regex, path.join(ROOT_PATH, suffix), newContext),
  );
};

if (specFilters.length) {
  // resolve filters
  let filteredSpecFiles = specFilters.map((filter) =>
    glob
      .sync(filter, {
        root: ROOT_PATH,
        matchBase: true,
      })
      .filter((filePath) => filePath.endsWith('spec.js')),
  );

  // flatten
  filteredSpecFiles = Array.prototype.concat.apply([], filteredSpecFiles);

  // remove duplicates
  filteredSpecFiles = [...new Set(filteredSpecFiles)];

  if (filteredSpecFiles.length < 1) {
    const isError = options.failOnEmptyTestSuite;

    exit('Your filter did not match any test files.', isError);
  }

  if (!filteredSpecFiles.every((file) => SPECS_PATH.test(file))) {
    exitError('Test files must be located within /spec/javascripts.');
  }

  const CE_FILES = filteredSpecFiles.filter((file) => !file.startsWith('ee'));
  createContext(CE_FILES, /[^e]{2}[\\/]spec[\\/]javascripts$/, 'spec/javascripts');

  const EE_FILES = filteredSpecFiles.filter((file) => file.startsWith('ee'));
  createContext(EE_FILES, /ee[\\/]spec[\\/]javascripts$/, 'ee/spec/javascripts');
}

// Karma configuration
module.exports = (config) => {
  process.env.TZ = 'Etc/UTC';

  const fixturesPath = `tmp/tests/frontend/fixtures${IS_EE ? '-ee' : ''}`;
  const staticFixturesPath = 'spec/frontend/fixtures/static';

  const karmaConfig = {
    basePath: ROOT_PATH,
    browsers: ['ChromeHeadlessCustom'],
    client: {
      color: !process.env.CI,
    },
    customLaunchers: {
      ChromeHeadlessCustom: {
        base: 'ChromeHeadless',
        displayName: 'Chrome',
        flags: [
          // chrome cannot run in sandboxed mode inside a docker container unless it is run with
          // escalated kernel privileges (e.g. docker run --cap-add=CAP_SYS_ADMIN)
          '--no-sandbox',
          // https://bugs.chromium.org/p/chromedriver/issues/detail?id=2870
          '--enable-features=NetworkService,NetworkServiceInProcess',
        ],
      },
    },
    frameworks: ['jasmine'],
    files: [
      { pattern: 'spec/javascripts/test_bundle.js', watched: false },
      { pattern: `${fixturesPath}/**/*`, included: false },
      { pattern: `${staticFixturesPath}/**/*`, included: false },
    ],
    proxies: {
      '/fixtures/': `/base/${fixturesPath}/`,
      '/fixtures/static/': `/base/${staticFixturesPath}/`,
    },
    preprocessors: {
      'spec/javascripts/**/*.js': ['webpack', 'sourcemap'],
      'ee/spec/javascripts/**/*.js': ['webpack', 'sourcemap'],
    },
    reporters: ['mocha'],
    webpack: webpackConfig,
    webpackMiddleware: { stats: 'errors-only' },
    plugins: [
      'karma-chrome-launcher',
      'karma-coverage-istanbul-reporter',
      'karma-jasmine',
      'karma-junit-reporter',
      'karma-mocha-reporter',
      'karma-sourcemap-loader',
      'karma-webpack',
    ],
  };

  if (process.env.CI) {
    karmaConfig.reporters.push('junit');
    karmaConfig.junitReporter = {
      outputFile: 'junit_karma.xml',
      useBrowserName: false,
    };
  } else {
    // ignore 404s in local environment because we are not fixing them and they bloat the log
    function ignore404() {
      return (request, response /* next */) => {
        response.writeHead(404);
        return response.end('NOT FOUND');
      };
    }

    karmaConfig.middleware = ['ignore-404'];
    karmaConfig.plugins.push({
      'middleware:ignore-404': ['factory', ignore404],
    });
  }

  if (process.env.BABEL_ENV === 'coverage' || process.env.NODE_ENV === 'coverage') {
    karmaConfig.reporters.push('coverage-istanbul');
    karmaConfig.coverageIstanbulReporter = {
      reports: ['html', 'text-summary', 'cobertura'],
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
