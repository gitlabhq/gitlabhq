const fs = require('fs');
const path = require('path');
const postcss = require('postcss');
const prettier = require('prettier');
const sass = require('sass');

const utils = require('./stylelint-utils');

const ROOT_PATH = path.resolve(__dirname, '../../..');
const hashMapPath = path.resolve(__dirname, './utility-classes-map.js');

//
// This creates a JS based hash map (saved in utility-classes-map.js) of the different values in the utility classes
//
sass.render(
  {
    data: `
      @import './functions';
      @import './variables';
      @import './mixins';
      @import './utilities';
    `,
    includePaths: [path.resolve(ROOT_PATH, 'node_modules/bootstrap/scss')],
  },
  (err, result) => {
    if (err) {
      return console.error('Error ', err);
    }

    const cssResult = result.css.toString();

    // We just use postcss to create a CSS tree
    return postcss([])
      .process(cssResult, {
        // This suppresses a postcss warning
        from: undefined,
      })
      .then((processedResult) => {
        const selectorGroups = {};
        utils.createPropertiesHashmap(
          processedResult.root,
          processedResult,
          null,
          null,
          selectorGroups,
          true,
        );

        const prettierOptions = prettier.resolveConfig.sync(hashMapPath);
        const prettyHashmap = prettier.format(
          `module.exports = ${JSON.stringify(selectorGroups)};`,
          prettierOptions,
        );

        fs.writeFile(hashMapPath, prettyHashmap, (e) => {
          if (e) {
            return console.log(e);
          }

          return console.log('The file was saved!');
        });
      });
  },
);
