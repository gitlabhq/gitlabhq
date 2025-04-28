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
  '@babel/plugin-transform-class-properties',
  '@babel/plugin-transform-json-strings',
  '@babel/plugin-transform-private-methods',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/229146
  '@babel/plugin-transform-arrow-functions',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-transform-optional-chaining',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-transform-nullish-coalescing-operator',
  'lodash',
  '@babel/plugin-transform-class-static-block',
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
