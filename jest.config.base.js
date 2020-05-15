const IS_EE = require('./config/helpers/is_ee_env');
const isESLint = require('./config/helpers/is_eslint');

module.exports = path => {
  const reporters = ['default'];

  // To have consistent date time parsing both in local and CI environments we set
  // the timezone of the Node process. https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/27738
  process.env.TZ = 'GMT';

  if (process.env.CI) {
    reporters.push([
      'jest-junit',
      {
        output: './junit_jest.xml',
      },
    ]);
  }

  const glob = `${path}/**/*_spec.js`;
  let testMatch = [`<rootDir>/${glob}`];
  if (IS_EE) {
    testMatch.push(`<rootDir>/ee/${glob}`);
  }

  // workaround for eslint-import-resolver-jest only resolving in test files
  // see https://github.com/JoinColony/eslint-import-resolver-jest#note
  if (isESLint(module)) {
    testMatch = testMatch.map(path => path.replace('_spec.js', ''));
  }

  const moduleNameMapper = {
    '^~(/.*)$': '<rootDir>/app/assets/javascripts$1',
    '^ee_component(/.*)$':
      '<rootDir>/app/assets/javascripts/vue_shared/components/empty_component.js',
    '^ee_else_ce(/.*)$': '<rootDir>/app/assets/javascripts$1',
    '^helpers(/.*)$': '<rootDir>/spec/frontend/helpers$1',
    '^vendor(/.*)$': '<rootDir>/vendor/assets/javascripts$1',
    '\\.(jpg|jpeg|png|svg|css)$': '<rootDir>/spec/frontend/__mocks__/file_mock.js',
    'emojis(/.*).json': '<rootDir>/fixtures/emojis$1.json',
    '^spec/test_constants$': '<rootDir>/spec/frontend/helpers/test_constants',
    '^jest/(.*)$': '<rootDir>/spec/frontend/$1',
  };

  const collectCoverageFrom = ['<rootDir>/app/assets/javascripts/**/*.{js,vue}'];

  if (IS_EE) {
    const rootDirEE = '<rootDir>/ee/app/assets/javascripts$1';
    Object.assign(moduleNameMapper, {
      '^ee(/.*)$': rootDirEE,
      '^ee_component(/.*)$': rootDirEE,
      '^ee_else_ce(/.*)$': rootDirEE,
      '^ee_jest/(.*)$': '<rootDir>/ee/spec/frontend/$1',
    });

    collectCoverageFrom.push(rootDirEE.replace('$1', '/**/*.{js,vue}'));
  }

  const coverageDirectory = () => {
    if (process.env.CI_NODE_INDEX && process.env.CI_NODE_TOTAL) {
      return `<rootDir>/coverage-frontend/jest-${process.env.CI_NODE_INDEX}-${process.env.CI_NODE_TOTAL}`;
    }

    return '<rootDir>/coverage-frontend/';
  };

  return {
    clearMocks: true,
    testMatch,
    moduleFileExtensions: ['js', 'json', 'vue'],
    moduleNameMapper,
    collectCoverageFrom,
    coverageDirectory: coverageDirectory(),
    coverageReporters: ['json', 'lcov', 'text-summary', 'clover'],
    cacheDirectory: '<rootDir>/tmp/cache/jest',
    modulePathIgnorePatterns: ['<rootDir>/.yarn-cache/'],
    reporters,
    setupFilesAfterEnv: ['<rootDir>/spec/frontend/test_setup.js', 'jest-canvas-mock'],
    restoreMocks: true,
    transform: {
      '^.+\\.(gql|graphql)$': 'jest-transform-graphql',
      '^.+\\.js$': 'babel-jest',
      '^.+\\.vue$': 'vue-jest',
    },
    transformIgnorePatterns: ['node_modules/(?!(@gitlab/ui|bootstrap-vue|three|monaco-editor)/)'],
    timers: 'fake',
    testEnvironment: '<rootDir>/spec/frontend/environment.js',
    testEnvironmentOptions: {
      IS_EE,
    },
  };
};
