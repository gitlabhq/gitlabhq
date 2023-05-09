const coreJSVersion = require('./node_modules/core-js/package.json').version;

let presets = [
  [
    '@babel/preset-env',
    {
      useBuiltIns: 'usage',
      bugfixes: true,
      corejs: { version: coreJSVersion, proposals: true },
      modules: false,
    },
  ],
];

// include stage 3 proposals
const plugins = [
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

// Jest is running in node environment
const isJest = Boolean(process.env.JEST_WORKER_ID);
if (isJest) {
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
