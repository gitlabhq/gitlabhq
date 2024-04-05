#!/usr/bin/env node

/* eslint-disable import/extensions */

import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import _ from 'lodash';
import postcss from 'postcss';
import prettier from 'prettier';

import tailwindcss from 'tailwindcss/lib/plugin.js';
import {
  classesWithRawColors,
  extractRules,
  loadCSSFromFile,
  mismatchAllowList,
  normalizeCssInJSDefinition,
} from './lib/tailwind_migration.mjs';
import { compileAllStyles } from './lib/compile_css.mjs';
import { build as buildTailwind } from './tailwindcss.mjs';

const PATH_TO_FILE = path.resolve(fileURLToPath(import.meta.url));
const ROOT_PATH = path.resolve(path.dirname(PATH_TO_FILE), '../../');
const tempDir = path.join(ROOT_PATH, 'config', 'helpers', 'tailwind');
const allUtilitiesFile = path.join(tempDir, './all_utilities.haml');

export async function convertUtilsToCSSInJS() {
  console.log('# Compiling legacy styles');

  await compileAllStyles({
    style: 'expanded',
    filter: (source) => source.includes('application_utilities_to_be_replaced'),
  });

  fs.mkdirSync(tempDir, { recursive: true });

  const oldUtilityDefinitions = extractRules(
    loadCSSFromFile('app/assets/builds/application_utilities_to_be_replaced.css'),
    { convertColors: true },
  );

  // Write out all found css classes in order to run tailwind on it.
  fs.writeFileSync(
    allUtilitiesFile,
    Object.keys(oldUtilityDefinitions)
      .map((clazz) => {
        return (
          // Add `gl-` prefix to all classes
          `.gl-${clazz.substring(1)}`
            // replace the escaped `\!` with !
            .replace(/\\!/g, '!')
        );
      })
      .join('\n'),
  );

  // Lazily require
  const { default: tailwindConfig } = await import('../../config/tailwind.all_the_way.config.js');

  const { css: tailwindClasses } = await postcss([
    tailwindcss({
      ...tailwindConfig,
      // We only want to generate the utils based on the fresh
      // allUtilitiesFile
      content: [allUtilitiesFile],
      // We are disabling all plugins, so that the css-to-js
      // import doesn't cause trouble.
      plugins: [],
    }),
  ]).process('@tailwind utilities;', { map: false, from: undefined });

  const tailwindDefinitions = extractRules(tailwindClasses);

  const deleted = [];
  const mismatches = [];

  for (const definition of Object.keys(tailwindDefinitions)) {
    if (
      mismatchAllowList.includes(definition) ||
      normalizeCssInJSDefinition(oldUtilityDefinitions[definition]) ===
        normalizeCssInJSDefinition(tailwindDefinitions[definition])
    ) {
      delete oldUtilityDefinitions[definition];
      deleted.push(definition);
    } else if (oldUtilityDefinitions[definition]) {
      console.log(`Found ${definition} in both, but they don't match:`);
      console.log(`\tOld: ${JSON.stringify(oldUtilityDefinitions[definition])}`);
      console.log(`\tNew: ${JSON.stringify(tailwindDefinitions[definition])}`);
      mismatches.push([
        definition,
        oldUtilityDefinitions[definition],
        tailwindDefinitions[definition],
      ]);
      delete oldUtilityDefinitions[definition];
    }
  }

  console.log(
    `Deleted exact matches:\n\t${_.chunk(deleted, 4)
      .map((n) => n.join(' '))
      .join('\n\t')}`,
  );

  const hardcodedColors = _.pick(oldUtilityDefinitions, classesWithRawColors);
  const safeToUse = _.omit(oldUtilityDefinitions, classesWithRawColors);

  const stats = {
    exactMatches: deleted.length,
    potentialMismatches: Object.keys(mismatches).length,
    hardcodedColors: Object.keys(hardcodedColors).length,
    safeToUseLegacyUtils: Object.keys(safeToUse).length,
  };

  console.log(stats);

  const output = await prettier.format(
    [
      stats.potentialMismatches &&
        `
/* eslint-disable no-unused-vars */
// The following rules are mismatches between our utility classes and
// tailwinds. So there are two rules in the old system and the new system
// with the same name, but their definitions mismatch.
// The mismatch might be minor, or major and needs to be dealt with manually
// the array below contains:
// [rule name, GitLab UI utility, tailwind utility]
const potentialMismatches = Object.fromEntries(
${JSON.stringify(mismatches, null, 2)}
);`,
      stats.hardcodedColors &&
        `
// The following definitions have hard-coded colors and do not use
// their var(...) counterparts. We should double-check them and fix them
// manually (e.g. the text- classes should use the text variables and not
// gray-)
const hardCodedColors = ${JSON.stringify(hardcodedColors, null, 2)};
`,
      `module.exports = {`,
      stats.hardcodedColors && '...hardCodedColors,',
      `...${JSON.stringify(safeToUse, null, 2)}`,
      '}',
    ]
      .filter(Boolean)
      .join(''),
    {
      printWidth: 100,
      singleQuote: true,
      arrowParens: 'always',
      trailingComma: 'all',
      parser: 'babel',
    },
  );

  fs.writeFileSync(path.join(tempDir, './css_in_js.js'), output);

  console.log('# Rebuilding tailwind-all-the-way');

  await buildTailwind({ tailWindAllTheWay: true });

  return stats;
}

if (PATH_TO_FILE.includes(path.resolve(process.argv[1]))) {
  console.log('Script called directly.');
  convertUtilsToCSSInJS().catch((e) => {
    console.warn(e);
    process.exitCode = 1;
  });
}
