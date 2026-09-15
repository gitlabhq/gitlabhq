const coreJSVersion = require('./node_modules/core-js/package.json').version;

if (process.env.DEBUG_BABEL_ENV === 'true') {
  console.debug(`BABEL_ENV inside Babel config is: ${process.env.BABEL_ENV}`);
}

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
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-transform-optional-chaining',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-transform-nullish-coalescing-operator',
  // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
  '@babel/plugin-transform-logical-assignment-operators',
  '@babel/plugin-transform-class-static-block',
  '@babel/plugin-transform-export-namespace-from',
];

const env = {};
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
} else {
  env.istanbul = {
    plugins: [
      [
        'istanbul',
        {
          extension: ['.js', '.vue', '.mjs', '.cjs'],
        },
      ],
    ],
  };
}

module.exports = {
  presets,
  plugins,
  overrides: [
    {
      // See: https://gitlab.com/gitlab-org/gitlab/-/issues/229146
      // Only our own code needs this. On third-party code it breaks `this?.x`
      // default parameters: https://gitlab.com/gitlab-org/gitlab/-/work_items/628901
      // Only webpack sends node_modules through Babel. Once rspack replaces
      // webpack, this override can move back into `plugins`.
      exclude: /node_modules/,
      plugins: ['@babel/plugin-transform-arrow-functions'],
    },
  ],
  sourceType: 'unambiguous',
  env,
};
