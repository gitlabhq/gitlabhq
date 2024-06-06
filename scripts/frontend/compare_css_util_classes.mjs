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
import { convertUtilsToCSSInJS, toMinimalUtilities } from './tailwind_all_the_way.mjs';

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

function compareApplicationUtilsToTailwind(appUtils, tailwindCSS, colorResolver) {
  let fail = 0;

  const tailwind = extractRules(tailwindCSS);

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
      console.warn(`Compared: [legacy util => tailwind util]`);
      console.warn(e.message.replace(/\n/g, '\n\t'));
    }
  });

  if (fail) {
    console.log(`\t${fail} selectors failed`);
  } else {
    console.log('\tAll good');
  }

  return fail;
}

function ensureNoLegacyUtilIsUsedWithATailwindModifier(minimalUtils) {
  let fail = 0;
  for (const [key, value] of Object.entries(minimalUtils)) {
    if (key.startsWith('.\\!')) {
      console.warn('Using legacy util with important modifier. This is not supported.');
      console.warn(`Please migrate ${key} to a proper tailwind util.`);
      fail += 1;
    }
    if (key.endsWith('\\')) {
      console.warn(`Using legacy util with ${key} modifier. This is not supported.`);
      console.warn(`Please migrate the following classes to a proper tailwind util:`);
      console.warn(JSON.stringify(value, null, 2).replace(/^/gm, ' '.repeat(4)));
      fail += 1;
    }
  }
  if (fail) {
    console.log(`\t${fail} legacy utils with modifiers found`);
  }
  return fail;
}

console.log('# Converting legacy styles to CSS-in-JS definitions');

const stats = await convertUtilsToCSSInJS();

if (stats.hardcodedColors || stats.potentialMismatches) {
  console.warn(`Some utils are not properly mapped`);
  process.exitCode = 1;
}

let failures = 0;

console.log('# Comparing tailwind to legacy utils');

const applicationUtilsLight = extractRules(
  loadCSSFromFile('app/assets/builds/application_utilities_to_be_replaced.css'),
  { convertColors: true },
);
const applicationUtilsDark = extractRules(
  loadCSSFromFile('app/assets/builds/application_utilities_to_be_replaced_dark.css'),
  { convertColors: true },
);
const tailwind = loadCSSFromFile('app/assets/builds/tailwind.css');

console.log('## Comparing tailwind light mode');
failures += compareApplicationUtilsToTailwind(applicationUtilsLight, tailwind);
console.log('## Comparing tailwind dark mode');
failures += compareApplicationUtilsToTailwind(applicationUtilsDark, tailwind, darkModeResolver);

console.log('# Checking whether legacy GitLab utility classes are used with tailwind modifiers');

console.log('## Reducing utility definitions to minimally used');
const { rules } = await toMinimalUtilities();

console.log('## Running checks');
failures += ensureNoLegacyUtilIsUsedWithATailwindModifier(rules);

if (failures) {
  process.exitCode = 1;
} else {
  console.log('# All good – Happiness. May the tailwind boost your journey');
}
