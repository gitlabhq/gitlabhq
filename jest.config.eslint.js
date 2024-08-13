module.exports = {
  testMatch: ['<rootDir>/spec/tooling/frontend/eslint-config/**/*@([._])spec.js'],
  transform: {
    '^.+\\.js$': 'babel-jest',
  },
  transformIgnorePatterns: [`node_modules/`],
};
