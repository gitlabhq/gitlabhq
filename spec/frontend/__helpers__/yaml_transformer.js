/* eslint-disable import/no-commonjs */
const JsYaml = require('js-yaml');

// This will transform YAML files to JSON strings
module.exports = {
  process: (sourceContent) => {
    const jsonContent = JsYaml.load(sourceContent);
    const json = JSON.stringify(jsonContent);
    return { code: `module.exports = ${json}` };
  },
};
