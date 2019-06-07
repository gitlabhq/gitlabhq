const sass = require('node-sass');
const postcss = require('postcss');
const fs = require('fs');
const path = require('path');
const prettier = require('prettier');

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
    if (err) console.error('Error ', err);

    const cssResult = result.css.toString();

    // We just use postcss to create a CSS tree
    postcss([])
      .process(cssResult, {
        // This suppresses a postcss warning
        from: undefined,
      })
      .then(result => {
        const selectorGroups = {};
        utils.createPropertiesHashmap(result.root, result, null, null, selectorGroups, true);

        const prettierOptions = prettier.resolveConfig.sync(hashMapPath);
        const prettyHashmap = prettier.format(
          `module.exports = ${JSON.stringify(selectorGroups)};`,
          prettierOptions,
        );

        fs.writeFile(hashMapPath, prettyHashmap, function(err) {
          if (err) {
            return console.log(err);
          }

          console.log('The file was saved!');
        });
      });
  },
);
