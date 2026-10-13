/* eslint-disable import-x/no-commonjs */
module.exports = {
  process: (content) => {
    return { code: `module.exports = ${JSON.stringify(content)}` };
  },
};
