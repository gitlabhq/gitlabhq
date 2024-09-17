#!/usr/bin/env node

/* eslint-disable import/extensions */

const { readFile } = require('node:fs/promises');
const path = require('node:path');
const _ = require('lodash');
const postcss = require('postcss');
const tailwindPlugin = require('tailwindcss/plugin.js');
const tailwindcss = require('tailwindcss/lib/plugin.js');
const tailwindConfig = require('../../config/tailwind.config.js');

const ROOT_PATH = path.resolve(__dirname, '../../');
const tailwindSource = path.join(ROOT_PATH, 'app/assets/stylesheets/tailwind.css');
const legacyUtilsSource = path.join(ROOT_PATH, 'node_modules/@gitlab/ui/dist/utility_classes.css');

/**
 * Strips trailing modifiers like `:hover`, `::before` from selectors,
 * only returning the class name
 *
 * For example: .gl-foo-hover-bar:hover will be turned into: .gl-foo-bar
 * @param {String} selector
 * @returns {String}
 */
function getCleanSelector(selector) {
  return selector.replace(/:.*/, '');
}

/**
 * Extracts all class names from a CSS file
 *
 * @param {String} css
 * @returns {Set<String>}
 */
function extractClassNames(css) {
  const definitions = new Set();

  postcss.parse(css).walkRules((rule) => {
    // We skip all atrule, e.g. @keyframe, except @media queries
    if (rule.parent?.type === 'atrule' && rule.parent?.name !== 'media') {
      console.log(`Skipping atrule of type ${rule.parent?.name}`);
      return;
    }

    // This is an odd dark-mode only util. We have added it to the dark mode overrides
    // and remove it from our utility classes
    if (rule.selector.startsWith('.gl-dark .gl-dark-invert-keep-hue')) {
      console.log(`Skipping composite selector ${rule.selector} which will be migrated manually`);
      return;
    }

    // iterate over each class definition
    rule.selectors.forEach((selector) => {
      definitions.add(getCleanSelector(selector));
    });
  });

  return definitions;
}

/**
 * Writes the CSS in Js in compatibility mode. We write all the utils and we surface things we might
 * want to look into (hardcoded colors, definition mismatches).
 *
 * @param {Set<String>} tailwindClassNames
 * @param {Set<String>} oldClassNames
 */
async function compareLegacyClassesWithTailwind(tailwindClassNames, oldClassNames) {
  const oldUtilityNames = new Set(oldClassNames);

  const deleted = new Set();

  for (const definition of tailwindClassNames) {
    if (oldUtilityNames.has(definition)) {
      oldUtilityNames.delete(definition);
      deleted.add(definition);
    }
  }

  console.log(
    `Legacy classes which have a tailwind equivalent:\n\t${_.chunk(Array.from(deleted), 4)
      .map((n) => n.join(' '))
      .join('\n\t')}`,
  );

  return { oldUtilityNames };
}

/**
 * Runs tailwind on the whole code base, but with mock utilities only.
 *
 * We hand in a Set of class names (e.g. `.foo-bar`, `.bar-baz`) and tailwind will run
 * if one of our source files contains e.g. `.gl-foo-bar` or `.gl-bar-baz`,
 * it will be returned
 *
 * @param {Set<String>} oldClassNames
 * @param {Array<string>} content
 * @returns {Promise<{rules: Set<String>}>}
 */
async function toMinimalUtilities(oldClassNames, content = []) {
  const { css: tailwindClasses } = await postcss([
    tailwindcss({
      ...tailwindConfig,
      content: Array.isArray(content) && content.length > 0 ? content : tailwindConfig.content,
      // We must ensure the GitLab UI plugin is disabled during this run so that whatever it defines
      // is purged out of the CSS-in-Js.
      presets: [
        {
          ...tailwindConfig.presets[0],
          plugins: [],
        },
      ],
      // Disable all core plugins, all we care about are the legacy utils
      // that are provided via addUtilities.
      corePlugins: [],
      plugins: [
        tailwindPlugin(({ addUtilities }) => {
          addUtilities(
            Object.fromEntries(
              Array.from(oldClassNames).map((className) => [
                // Strip leading `.gl-` because tailwind will add the prefix itself
                className.replace(/^\.gl-/, '.'),
                { width: 0 },
              ]),
            ),
          );
        }),
      ],
    }),
  ]).process('@tailwind utilities;', { map: false, from: undefined });

  const rules = tailwindClasses
    .replace(/@.+?{([\s\S]+?)}/gim, '$1')
    .replace(/\{[\s\S]+?}/gim, '')
    .split('\n')
    .map((x) => x.trim())
    .filter(Boolean);

  return { rules: new Set(rules) };
}

async function lintAgainstLegacyUtils({ content = [] } = {}) {
  console.log('# Checking whether legacy GitLab utility classes are used');

  console.log('## Extracting legacy util class names');

  const legacyClassNames = extractClassNames(await readFile(legacyUtilsSource, 'utf-8'));

  /**
   * Document containing all utilities at least once, like this:
   *
   * <div class="gl-display-flex">
   * <div class="gl-foo-bar">
   * @type {string}
   */
  const allLegacyDocument = Array.from(legacyClassNames)
    .map((className) => {
      const cleanClass = className
        .substring(1)
        // replace escaped `\!` with !
        .replace(/\\!/g, '!');

      return `<div class="${cleanClass}"></div>`;
    })
    .join('\n');

  const { css } = await postcss([
    tailwindcss({
      ...tailwindConfig,
      content: [{ raw: allLegacyDocument, extension: 'html' }],
      // We are disabling all plugins to prevent the CSS-in-Js import from causing trouble.
      // The GitLab UI preset still registers its own plugin, which we need to define legitimate
      // custom utils.
      plugins: [],
    }),
  ]).process(await readFile(tailwindSource, 'utf-8'), { map: false, from: undefined });

  const tailwindClassNames = extractClassNames(css);

  console.log('## Comparing legacy utils to current tailwind class names');

  const { oldUtilityNames } = await compareLegacyClassesWithTailwind(
    tailwindClassNames,
    legacyClassNames,
  );

  console.log('## Checking whether a legacy class name is used');

  const { rules } = await toMinimalUtilities(oldUtilityNames, content);

  console.log(`Went from ${oldUtilityNames.size} => ${rules.size} utility classes`);

  if (rules.size > 0) {
    const message = `You are introducing legacy utilities:
\t${Array.from(rules).sort().join('\n\t')}
Please migrate them to tailwind utilities:
https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/tailwind-migration.md`;
    throw new Error(message);
  }
}

function wasScriptCalledDirectly() {
  return process.argv[1] === __filename;
}

if (wasScriptCalledDirectly()) {
  lintAgainstLegacyUtils()
    .then(() => {
      console.log('# All good – Happiness. May the tailwind boost your journey');
    })
    .catch((e) => {
      console.warn('An error happened');
      console.warn(e.message);
      process.exitCode = 1;
    });
}

module.exports = {
  lintAgainstLegacyUtils,
};
