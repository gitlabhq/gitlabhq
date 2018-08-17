const path = require('path');
const glob = require('glob');
const chalk = require('chalk');
const webpack = require('webpack');
const argumentsParser = require('commander');
const escapeRegex = require('escape-string-regexp');
const webpackConfig = require('./webpack.config.js');

const ROOT_PATH = path.resolve(__dirname, '..');
const TEST_CONTEXT_PATH = 'spec/javascripts';
const CODE_CONTEXT_PATH = 'app/assets/javascripts';

function fatalError(message) {
  console.error(chalk.red(`\nError: ${message}\n`));
  process.exit(1);
}

// disable problematic options
webpackConfig.entry = undefined;
webpackConfig.mode = 'development';
webpackConfig.optimization.nodeEnv = false;
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

function createContext(root, globs) {
  const context = {};
  let specFilePaths = []
    .concat(globs)
    .map(filter =>
      glob.sync(filter, { root, matchBase: true }).filter(path => path.endsWith('spec.js'))
    );

  // flatten results
  specFilePaths = Array.prototype.concat.apply([], specFilePaths);

  // remove duplicates
  specFilePaths = [...new Set(specFilePaths)];

  // generate context relative to root
  specFilePaths.forEach(file => (context[file] = path.join(root, file)));
  return context;
}

console.log(`Locating tests files...`);

const testContext = createContext(
  ROOT_PATH,
  /* specFilters || */ `**/${TEST_CONTEXT_PATH}/**/*spec.js`
);
const codeContext = {}; //createContext(ROOT_PATH, `**/${CODE_CONTEXT_PATH}/**/*.js`);
const testList = Object.keys(testContext);

if (!testList.length) {
  fatalError('Your filter did not match any test files.');
}

if (!testList.every(file => file.includes(TEST_CONTEXT_PATH))) {
  fatalError('Test files must be located within spec/javascripts.');
}

console.log(`Found ${testList.length} test files`);
console.log(testContext);

// Override webpack require contexts within test_bundle
webpackConfig.resolve.alias['KARMA_TEST_CONTEXT$'] = path.join(ROOT_PATH, TEST_CONTEXT_PATH);
webpackConfig.resolve.alias['KARMA_CODE_CONTEXT$'] = path.join(ROOT_PATH, CODE_CONTEXT_PATH);
const KARMA_TEST_CONTEXT_REGEX = new RegExp(`${escapeRegex(TEST_CONTEXT_PATH)}$`);
const KARMA_CODE_CONTEXT_REGEX = new RegExp(`${escapeRegex(CODE_CONTEXT_PATH)}$`);
webpackConfig.plugins.push(
  new webpack.ContextReplacementPlugin(
    KARMA_TEST_CONTEXT_REGEX,
    path.join(ROOT_PATH, TEST_CONTEXT_PATH),
    testContext
  ),
  new webpack.ContextReplacementPlugin(
    KARMA_CODE_CONTEXT_REGEX,
    path.join(ROOT_PATH, CODE_CONTEXT_PATH),
    codeContext
  )
);

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
