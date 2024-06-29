#!/usr/bin/env node

/**
 * @file This file generates a
 * [jsconfig.json](https://code.visualstudio.com/docs/languages/jsconfig) file
 * using aliases from the webpack config. To use it run from project root:
 *
 * ```sh
 * node ./scripts/frontend/create_jsconfig.js
 * ```
 *
 * NOTE: since aliases are currently generated based on solely Webpack config,
 * aliases defined in Jest config might be missing.
 */

const fs = require('node:fs/promises');
const path = require('node:path');
const readline = require('node:readline/promises');
const { stdin, stdout } = require('node:process');
const chalk = require('chalk').default;
const prettier = require('prettier');

const PATH_PROJECT_ROOT = path.resolve(__dirname, '..', '..');
const PATH_JS_CONFIG = path.join(PATH_PROJECT_ROOT, 'jsconfig.json');

/**
 * Creates and writes a jsconfig.json file, based on Webpack aliases.
 */
async function createJsConfig() {
  // eslint-disable-next-line global-require
  const webpackConfig = require('../../config/webpack.config');

  // Aliases
  const paths = {};
  const WEBPACK_ALIAS_EXCEPTIONS = ['jquery$', '@gitlab/svgs/dist/icons.svg', '@apollo/client$'];
  Object.entries(webpackConfig.resolve.alias)
    .filter(([key]) => !WEBPACK_ALIAS_EXCEPTIONS.includes(key))
    .forEach(([key, value]) => {
      const alias = `${key}/*`;
      const target = [`${path.relative(PATH_PROJECT_ROOT, value)}/*`];
      paths[alias] = target;
    });

  // JS/TS config. See more: https://www.typescriptlang.org/tsconfig
  const jsConfig = {
    // As we're introducing jsconfig to the project, as a precaution we add both:
    // 'include' and 'exclude' options. This might be simplified in the future.
    exclude: ['node_modules', 'vendor'],

    // 'include' is currently manually defined. We might want to append manually
    // defined paths with paths from aliases
    include: [
      'app/assets/javascripts',
      'ee/app/assets/javascripts',
      'spec/frontend',
      'ee/spec/frontend',
      'tmp/tests/frontend/fixtures',
      'tmp/tests/frontend/fixtures-ee',
    ],

    // Explicitly enable automatic type acquisition
    // See more: https://www.typescriptlang.org/tsconfig#type-acquisition
    typeAcquisition: {
      enable: true,
    },

    compilerOptions: {
      baseUrl: '.', // Define the project root
      checkJs: false, // Disable type checking on JavaScript files
      disableSizeLimit: true, // Disable memory size limit for the language server
      skipLibCheck: true, // Skip type checking all .d.ts files
      resolveJsonModule: true, // Enable importing .json files
      paths, // Aliases
    },
  };

  // Stringify, format and update the config file
  const jsConfigString = await prettier.format(JSON.stringify(jsConfig, null, 2), {
    parser: 'json',
  });
  await fs.writeFile(PATH_JS_CONFIG, jsConfigString);
}

function fileExists(filePath) {
  return fs.stat(filePath).then(
    () => true,
    () => false,
  );
}

async function main() {
  const jsconfigExists = await fileExists(PATH_JS_CONFIG);

  if (jsconfigExists) {
    console.log(`${chalk.yellow('WARNING:')} jsconfig.json file already exists.`);
    console.log('');
    const rl = readline.createInterface({ input: stdin, output: stdout });
    const response = await rl.question('Would you like to overwrite it? (y/n) ');
    rl.close();
    console.log('');

    const shouldOverwrite = response.match(/^y(es)?$/i);

    if (!shouldOverwrite) {
      console.log('Overwrite cancelled.');
      return;
    }
  }

  try {
    await createJsConfig();
    console.log(chalk.green('jsconfig.json file created.'));
  } catch (error) {
    console.log(`${chalk.red('ERROR:')} failed to create jsconfig.json. See the error below:`);
    console.error(error);
  }
}

main();
