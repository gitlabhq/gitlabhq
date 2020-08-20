/* eslint-disable import/no-commonjs, filenames/match-regex */

const BABEL_ENV = process.env.BABEL_ENV || process.env.NODE_ENV || null;

let presets = [
  [
    '@babel/preset-env',
    {
      useBuiltIns: 'usage',
      corejs: { version: 3, proposals: true },
      modules: false,
      /**
       * This list of browsers is a conservative first definition, based on
       * https://docs.gitlab.com/ee/install/requirements.html#supported-web-browsers
       * with the following reasoning:
       *
       * - Edge: Pick the last two major version before the Chrome switch
       * - Rest: We should support the latest ESR of Firefox: 68, because it used quite a lot.
       *         For the rest, pick browser versions that have a similar age to Firefox 68.
       *
       * See also this follow-up epic:
       * https://gitlab.com/groups/gitlab-org/-/epics/3957
       */
      targets: {
        chrome: '73',
        edge: '17',
        firefox: '68',
        safari: '12',
      },
    },
  ],
];

// include stage 3 proposals
const plugins = [
  '@babel/plugin-syntax-import-meta',
  '@babel/plugin-proposal-class-properties',
  '@babel/plugin-proposal-json-strings',
  '@babel/plugin-proposal-private-methods',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/229146
  '@babel/plugin-transform-arrow-functions',
  'lodash',
];

// add code coverage tooling if necessary
if (BABEL_ENV === 'coverage') {
  plugins.push([
    'babel-plugin-istanbul',
    {
      exclude: ['spec/javascripts/**/*', 'app/assets/javascripts/locale/**/app.js'],
    },
  ]);
}

// Jest is running in node environment, so we need additional plugins
const isJest = Boolean(process.env.JEST_WORKER_ID);
if (isJest) {
  plugins.push('@babel/plugin-transform-modules-commonjs');
  /*
  without the following, babel-plugin-istanbul throws an error:
  https://gitlab.com/gitlab-org/gitlab-foss/issues/58390
  */
  plugins.push('babel-plugin-dynamic-import-node');

  presets = [
    [
      '@babel/preset-env',
      {
        targets: {
          node: 'current',
        },
      },
    ],
  ];
}

module.exports = { presets, plugins, sourceType: 'unambiguous' };
