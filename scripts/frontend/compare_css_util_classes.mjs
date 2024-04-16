#!/usr/bin/env node

/* eslint-disable import/extensions */

import { deepEqual } from 'node:assert';

import {
  extractRules,
  loadCSSFromFile,
  normalizeCssInJSDefinition,
  darkModeTokenToHex,
  mismatchAllowList,
} from './lib/tailwind_migration.mjs';
import { convertUtilsToCSSInJS } from './tailwind_all_the_way.mjs';

function darkModeResolver(str) {
  return str.replace(
    /var\(--([^,]+?), #([a-f\d]{8}|[a-f\d]{6}|[a-f\d]{4}|[a-f\d]{3})\)/g,
    (_all, tokenName) => {
      if (darkModeTokenToHex[tokenName]) {
        return darkModeTokenToHex[tokenName];
      }

      return _all;
    },
  );
}

function compareApplicationUtilsToTailwind(appUtils, tailWind, colorResolver) {
  let fail = 0;

  const tailwind = extractRules(tailWind);

  Object.keys(appUtils).forEach((selector) => {
    if (mismatchAllowList.includes(selector)) {
      return;
    }

    try {
      deepEqual(
        normalizeCssInJSDefinition(appUtils[selector], colorResolver),
        normalizeCssInJSDefinition(tailwind[selector], colorResolver),
      );
    } catch (e) {
      fail += 1;
      console.warn(`Not equal ${selector}`);
      console.warn(e.message.replace(/\n/g, '\n\t'));
    }
  });

  if (fail) {
    console.log(`${fail} selectors failed`);
    process.exitCode = 1;
  }
}

console.log('# Converting legacy styles to CSS-in-JS definitions');

const stats = await convertUtilsToCSSInJS();

if (stats.hardcodedColors || stats.potentialMismatches) {
  console.warn(`Some utils are not properly mapped`);
  process.exitCode = 1;
}

console.log('# Comparing tailwind to legacy utils');

const applicationUtilsLight = extractRules(
  loadCSSFromFile('app/assets/builds/application_utilities_to_be_replaced.css'),
  { convertColors: true },
);
const applicationUtilsDark = extractRules(
  loadCSSFromFile('app/assets/builds/application_utilities_to_be_replaced_dark.css'),
  { convertColors: true },
);
const tailwind = loadCSSFromFile('app/assets/builds/tailwind_all_the_way.css');

compareApplicationUtilsToTailwind(applicationUtilsLight, tailwind);
compareApplicationUtilsToTailwind(applicationUtilsDark, tailwind, darkModeResolver);
