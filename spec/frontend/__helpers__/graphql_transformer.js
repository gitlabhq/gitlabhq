/* eslint-disable import/no-commonjs */
const loader = require('graphql-tag/loader');

module.exports = {
  process(src) {
    return loader.call({ cacheable() {} }, src);
  },
};
