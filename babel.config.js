const BABEL_ENV = process.env.BABEL_ENV || process.env.NODE_ENV || null;

let presets = [
  [
    '@babel/preset-env',
    {
      useBuiltIns: 'usage',
      corejs: { version: 3, proposals: true },
      modules: false,
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
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-proposal-optional-chaining',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-proposal-nullish-coalescing-operator',
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
