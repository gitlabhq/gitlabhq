import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import rgbHex from 'rgb-hex';
import postcss from 'postcss';
import _ from 'lodash';

const ROOT_PATH = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../');
const GITLAB_UI_DIR = path.join(ROOT_PATH, 'node_modules/@gitlab/ui');

// This is a list of classes where the tailwind and gitlab-ui output have a mismatch
// This might be due to e.g. the usage of custom properties on tailwinds side,
// or the usage of background vs background-image
export const mismatchAllowList = [
  // Shadows use some `--tw` attributes, but the output should be the same
  '.shadow-none',
  '.shadow',
  '.shadow-sm',
  '.shadow-md',
  '.shadow-lg',
  '.shadow-x0-y2-b4-s0',
  '.shadow-x0-y0-b3-s1-blue-500',
  // Difference between tailwind and gitlab ui: border-width: 0 vs border: 0
  '.sr-only',
  // tailwind uses --tw-rotate and --tw-translate custom properties
  // the reason for this: To make translate / rotate composable
  // Our utilities would overwrite each other
  '.translate-x-0',
  '.translate-y-0',
  '.rotate-90',
  '.rotate-180',
  // the border-style utils in tailwind do not allow for top, bottom, right, left
  '.border-b-solid',
  '.border-l-solid',
  '.border-r-solid',
  '.border-t-solid',
  // Our border shorthand classes are slightly different,
  // we migrated them by prepending them to the tailwind.css
  '.border',
  '.border-b',
  '.border-l',
  '.border-r',
  '.border-t',
  '.border\\!',
  '.border-b\\!',
  '.border-l\\!',
  '.border-r\\!',
  '.border-t\\!',
  // Tailwindy transparent border utils now leverage design tokens, the mismatches are expected.
  '.border-transparent',
  '.border-t-transparent',
  '.border-r-transparent',
  '.border-b-transparent',
  '.border-l-transparent',
  // Tailwind's line-clamp utils don't set `white-space: normal`, while our custom utils did.
  // We have added `gl-whitespace-normal` wherever line-clamp utils were being used, so these
  // mismatches can be ignored.
  '.line-clamp-1',
  '.line-clamp-2',
  '.line-clamp-3',
  '.outline-none',
  '.outline-0',
  // Tailwind's `bg-none` util applies `background-image: none` while ours does `background: none`.
  // Our recommendation is to use `bg-transparent` instead. Existing usages of `bg-none` have been
  // migrated to `bg-transparent` as of this comment.
  '.bg-none',
];

export function loadCSSFromFile(filePath) {
  return fs.readFileSync(path.join(ROOT_PATH, filePath), 'utf-8');
}

/**
 * A map of hex color codes to CSS variables replacements for utils where we can't
 * confidently automated the substitutions.
 * The keys correspond to a given util's base name obtained with the `selectorToBaseUtilName` helper.
 * Values are a map of hex color codes to CSS variable names.
 * If no replacement is necessary for a given util, the value should be an empty object.
 */
const hardcodedColorsToCSSVarsMap = {
  'animate-skeleton-loader': {
    '#dcdcde': '--gray-100',
    '#ececef': '--gray-50',
  },
  'inset-border-b-2-theme-accent': {
    '#6666c4': '--theme-indigo-500', // This gives us `var(--gl-theme-accent, var(--theme-indigo-500, #6666c4))` which I think is good
  },
  shadow: {}, // This util already uses hardcoded colors in its legacy version
  'shadow-x0-y2-b4-s0': {}, // This util already uses hardcoded colors in its legacy version
  'shadow-sm': {
    '#05050614': '--gl-color-alpha-dark-8', // The dark theme override does not yet exist
  },
  'shadow-md': {
    '#05050629': '--gl-color-alpha-dark-6', // The dark theme override does not yet exist
  },
  'shadow-lg': {
    '#05050629': '--gl-color-alpha-dark-6', // The dark theme override does not yet exist
  },
  'text-contrast-light': {}, // The legacy util references the $white-contrast variable for which we have no dark theme override
  'text-black-normal': {
    '#333': '--gl-text-color-default',
  },
  'text-body': {
    '#28272d': '--gl-text-color-default',
  },
  'text-secondary': {
    '#737278': '--gl-text-secondary',
  },
  'border-gray-a-08': {
    '#05050614': '--gl-color-alpha-dark-8', // The dark theme override does not yet exist
  },
  'inset-border-1-gray-a-08': {
    '#05050614': '--gl-color-alpha-dark-8', // The dark theme override does not yet exist
  },
  'border-gray-a-24': {
    '#0505063d': '--gl-color-alpha-dark-24', // The dark theme override does not yet exist
  },
  border: {
    '#dcdcde': '--gl-border-color-default',
  },
  'border-t': {
    '#dcdcde': '--gl-border-color-default',
  },
  'border-r': {
    '#dcdcde': '--gl-border-color-default',
  },
  'border-b': {
    '#dcdcde': '--gl-border-color-default',
  },
  'border-l': {
    '#dcdcde': '--gl-border-color-default',
  },
  '-focus': {
    '#fff': '--white',
    '#428fdc': '--blue-400',
  },
  'focus--focus': {
    '#fff': '--white',
    '#428fdc': '--blue-400',
  },
};
/**
 * Returns a flat array of token entries in the form:
 *
 * [['#123456','gray-500'],...]
 * @param tokens
 */
export function getColorTokens(tokens) {
  if (tokens.$type === 'color') {
    return [
      [
        // Normalize rgb(a) values to hex values.
        tokens.value.startsWith('rgb') ? `#${rgbHex(tokens.value)}` : tokens.value,
        tokens.path.join('-'),
      ],
    ];
  }
  if (tokens.$type) {
    return [];
  }

  return Object.values(tokens).flatMap((t) => getColorTokens(t));
}

/**
 * Returns a reverse mapping of hex values to tokens, e.g.
 *
 * {
 *   '#28272d': [ 'color-neutral-900', 'icon-color-strong', 'gray-900' ]
 * }
 *
 * @param rawTokens
 */
function buildColorToTokenMap(rawTokens) {
  const res = {};
  for (const [hex, token] of getColorTokens(rawTokens)) {
    res[hex] ||= [];
    res[hex].push(token);
    // Sort the token names by length because a shorter token name might be part
    // of a longer token name. e.g. `something-gray-900` contains `gray-900`.
    // But we want to resolve `gl-text-something-gray-900` to something-gray-900
    // and not `gray-900`
    res[hex].sort((a, b) => b.length - a.length);
  }
  return res;
}

/**
 * We get all tokens, but ignore the `text` tokens,
 * because the text tokens are correct, semantic tokens, but the values are
 * from our gray scale
 */
const { text, ...lightModeTokensRaw } = JSON.parse(
  fs.readFileSync(path.join(GITLAB_UI_DIR, 'src/tokens/build/json/tokens.json'), 'utf-8'),
);
const lightModeHexToToken = buildColorToTokenMap(lightModeTokensRaw);

export const darkModeTokenToHex = Object.fromEntries(
  getColorTokens(
    JSON.parse(
      fs.readFileSync(path.join(GITLAB_UI_DIR, 'src/tokens/build/json/tokens.dark.json'), 'utf-8'),
    ),
  ).map(([color, key]) => [key.startsWith('text-') ? `gl-${key}` : key, color]),
);

// We overwrite the following classes in
// app/assets/stylesheets/themes/_dark.scss
darkModeTokenToHex['gl-color-alpha-dark-8'] = '#fbfafd14'; // rgba($gray-950, 0.08);
darkModeTokenToHex['gl-text-secondary'] = '#bfbfc3'; // $gray-700

function isImportant(selector) {
  return selector.includes('!');
}

function getPseudoClass(selector) {
  const [, ...state] = selector.split(':');
  return state.length ? `&:${state.join(':')}` : '';
}

function getCleanSelector(selector) {
  return selector.replace('gl-', '').replace(/:.*/, '');
}

/**
 * Returns the plain util name from a given selector.
 * Essentially removes the leading dot, breakpoint prefix and important suffix if any.
 *
 * @param {string} cleanSelector The selector from which to extract the util name (should have been cleaned with getCleanSelector first)
 */
function selectorToBaseUtilName(cleanSelector) {
  return cleanSelector.replace(/^\.(sm-|md-|lg-)?/, '').replace(/\\!$/, '');
}

export const classesWithRawColors = [];

function normalizeColors(value, cleanSelector) {
  return (
    value
      // Replace rgb and rgba functions with hex syntax
      .replace(/rgba?\([\d ,./]+?\)/g, (rgbaColor) => `#${rgbHex(rgbaColor)}`)
      // Find corresponding token for color
      .replace(/#(?:[a-f\d]{8}|[a-f\d]{6}|[a-f\d]{4}|[a-f\d]{3})/gi, (hexColor) => {
        // transparent rgba hexex
        if (hexColor === '#0000' || hexColor === '#00000000') {
          return 'transparent';
        }

        // We only want to match a color,
        // if the selector contains the color name
        const tokenMatch = lightModeHexToToken[hexColor]?.find?.((tokenName) =>
          cleanSelector.includes(tokenName),
        );
        if (tokenMatch) {
          return `var(--${tokenMatch}, ${hexColor})`;
        }
        const utilName = selectorToBaseUtilName(cleanSelector);
        const cssVar = hardcodedColorsToCSSVarsMap[utilName]?.[hexColor];
        if (cssVar) {
          return `var(${cssVar}, ${hexColor})`;
        }

        // Only add this util to the list of hardcoded colors if it was not defined in the
        // `hardcodedColorsToCSSVarsMap` map.
        if (!hardcodedColorsToCSSVarsMap[utilName]) {
          classesWithRawColors.push(cleanSelector);
        }
        return hexColor;
      })
  );
}

export function extractRules(css, { convertColors = false } = {}) {
  const definitions = {};

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
      let styles = {};
      const cleanSelector = getCleanSelector(selector);

      // iterate over the properties of each class definition
      rule.nodes.forEach((node) => {
        styles[node.prop] = convertColors ? normalizeColors(node.value, cleanSelector) : node.value;

        if (isImportant(selector)) {
          styles[node.prop] += ' !important';
        }
      });

      const pseudoClass = getPseudoClass(selector);
      styles = pseudoClass
        ? {
            [pseudoClass]: styles,
          }
        : styles;
      if (rule.parent?.name === 'media') {
        styles = {
          [`@media ${rule.parent.params}`]: styles,
        };
      }
      /* merge existing definitions, because e.g.
       .class {
         width: 0;
       }
       @media(...) {
         .class {
           height: 0;
         }
       }
       needs to merged into:
       { '.class': {
         'width': 0;
         '@media(...)': {
           height: 0;
         }
       }}
      */
      definitions[cleanSelector] = { ...definitions[cleanSelector], ...styles };
    });
  });
  return definitions;
}

export function normalizeCssInJSDefinition(tailwindDefinition, colorResolver = false) {
  if (!tailwindDefinition) {
    return null;
  }

  // Order property definitions by name.
  const ordered = _.pick(tailwindDefinition, Object.keys(tailwindDefinition).sort());

  return JSON.stringify(ordered, (key, value) => {
    if (typeof value === 'string') {
      // Normalize decimal values without leading zeroes
      // e.g. 0.5px and .5px
      if (value.startsWith('0.')) {
        return value.substring(1);
      }
      // Normalize 0px and 0
      if (value === '0px') {
        return '0';
      }

      if (colorResolver) {
        return colorResolver(value);
      }
    }
    return value;
  });
}
