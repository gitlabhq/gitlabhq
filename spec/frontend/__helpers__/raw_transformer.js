/* eslint-disable import/no-commonjs */
module.exports = {
  process: (content) => {
    return { code: `module.exports = ${JSON.stringify(content)}` };
  },
};
