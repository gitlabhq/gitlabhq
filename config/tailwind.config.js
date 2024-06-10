const path = require('path');
const plugin = require('tailwindcss/plugin');
const tailwindDefaults = require('@gitlab/ui/tailwind.defaults');
const { range, round } = require('lodash');

// Try loading the tailwind css_in_js, in case they exist
let utilities = {};
try {
  // eslint-disable-next-line global-require, import/extensions
  utilities = require('./helpers/tailwind/css_in_js.js');
} catch (e) {
  console.log(
    'config/helpers/tailwind/css_in_js do not exist yet. Please run `scripts/frontend/tailwind_all_the_way.mjs`',
  );
  /*
  We need to remove the module itself from the cache, because node caches resolved modules.
  So if we:
  1. Require this file while helpers/tailwind/css_in_js.js does NOT exist
  2. Require this file again, when it exists, we would get the version from (1.) leading
     to errors.
  If we bust the cache in case css_in_js.js doesn't exist, we will get the proper version
     on a reload.
   */
  delete require.cache[path.resolve(__filename)];
}

function gitLabUIUtilities({ addUtilities }) {
  addUtilities({
    '.font-monospace': {
      'font-family':
        'var(--default-mono-font, "GitLab Mono"), "JetBrains Mono", "Menlo", "DejaVu Sans Mono", "Liberation Mono", "Consolas", "Ubuntu Mono", "Courier New", "andale mono", "lucida console", monospace',
      'font-variant-ligatures': 'none',
    },
    '.break-anywhere': {
      'overflow-wrap': 'anywhere',
      'word-break': 'normal',
    },
    '.wrap-anywhere': {
      'overflow-wrap': 'anywhere',
    },
  });
}

const widthPercentageScales = [8, 10, 20];

/** @type {import('tailwindcss').Config} */
module.exports = {
  presets: [tailwindDefaults],
  content: [
    './{ee,jh,}/app/assets/javascripts/**/*.{vue,js}',
    '!./app/assets/javascripts/locale/',
    './{ee,jh,}/app/helpers/**/*.rb',
    './{ee,jh,}/app/components/**/*.{haml,rb}',
    './{ee,jh,}/app/views/**/*.haml',
    './node_modules/@gitlab/ui/dist/**/*.{vue,js}',
  ],
  blocklist: [
    // Prevents an irrelevant util from being generated.
    // In the long run, we'll look into disabling arbitrary values altogether, which should prevent
    // this from happening. For now, we are simply blocking the only problematic occurrence.
    '[link:page-slug]',
  ],
  corePlugins: {
    /*
    We set background: none, Tailwind background-image: none...
    Probably compatible enough?
    We could also extend the theme, so that we use background: none in tailwind
     */
    backgroundImage: false,
    /*
    Disable preflight styles so that `@tailwind base` compiles to CSS vars declarations without
    any of the resets which we don't need.
    More on this at https://tailwindcss.com/docs/preflight.
     */
    preflight: false,
  },
  theme: {
    // TODO: Backport to GitLab UI
    fontFamily: {
      regular:
        'var(--default-regular-font, "GitLab Sans"), -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Sans", Ubuntu, Cantarell, "Helvetica Neue", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"',
    },
    // TODO: Backport to GitLab UI
    opacity: {
      0: '0',
      1: '.1',
      2: '.2',
      3: '.3',
      4: '.4',
      5: '.5',
      6: '.6',
      7: '.7',
      8: '.8',
      9: '.9',
      10: '1',
    },
    // TODO: Backport to GitLab UI
    zIndex: {
      0: '0',
      1: '1',
      2: '2',
      3: '3',
      200: '200',
      9999: '9999',
    },
    // TODO: Backport to GitLab UI.
    lineHeight: {
      reset: 'inherit',
      0: '0',
      1: '1',
      normal: '1rem',
      20: '1.25rem',
      24: '1.5rem',
      28: '1.75rem',
      32: '2rem',
      36: '2.25rem',
      42: '2.625rem',
    },
    transitionDuration: {
      DEFAULT: '200ms',
      slow: '400ms',
      medium: '200ms',
      fast: '100ms',
    },
    // These extends probably should be moved to GitLab UI:
    extend: {
      // TODO: Backport to GitLab UI. This should be part of the default colors config.
      colors: {
        current: 'currentColor',
        inherit: 'inherit',
      },
      borderWidth: {
        // We have a border-1 class, while tailwind was missing it
        1: '1px',
      },
      borderRadius: {
        // Tailwind gl-rounded-full is 9999px
        full: '50%',
      },
      boxShadow: {
        none: 'none',
        // TODO: I don't think we have a --t-gray matching class... --t-gray-a-24 seems close
        DEFAULT: '0 1px 4px 0 #0000004d',
        sm: '0 1px 2px var(--t-gray-a-08, #1f1e2414)',
        md: '0 2px 8px var(--t-gray-a-16, #1f1e2429), 0 0 2px var(--t-gray-a-16, #1f1e2429)',
        lg: '0 4px 12px var(--t-gray-a-16, #1f1e2429), 0 0 4px var(--t-gray-a-16, #1f1e2429)',

        // TODO: backport these inset box shadows to GitLab UI
        'inner-1-gray-100': 'inset 0 0 0 1px var(--gray-100, #dcdcde)',
        'inner-b-1-gray-100': 'inset 0 -1px 0 0 var(--gray-100, #dcdcde)',
        'inner-1-gray-200': 'inset 0 0 0 1px var(--gray-200, #bfbfc3)',
        'inner-l-4-gray-100': 'inset 4px 0 0 0 var(--gray-100, #dcdcde)',
        'inner-1-red-400': 'inset 0 0 0 1px var(--red-400, #ec5941)',
        'inner-1-gray-400': 'inset 0 0 0 1px var(--gray-400, #89888d)',
        'inner-2-blue-400': 'inset 0 0 0 2px var(--blue-400, #428fdc)',
        'inner-1-blue-500': 'inset 0 0 0 1px var(--blue-500, #1f75cb)',
        'inner-1-red-500': 'inset 0 0 0 1px var(--red-500, #dd2b0e)',
        'inner-l-3-red-600': 'inset 3px 0 0 0 var(--red-600, #c91c00)',
        'inner-b-2-theme-accent':
          'inset 0 -2px 0 0 var(--gl-theme-accent, var(--theme-indigo-500, #6666c4))',
        'x0-y2-b4-s0': '0 2px 4px 0 #0000001a',
        'x0-y0-b3-s1-blue-500': 'inset 0 0 3px 1px var(--blue-500, #1f75cb)',
      },
      // TODO: backport these width percentage classes to GitLab UI
      width: widthPercentageScales.reduce((accumulator1, denominator) => {
        return {
          ...accumulator1,
          ...range(1, denominator).reduce((accumulator2, numerator) => {
            const width = (numerator / denominator) * 100;

            return {
              ...accumulator2,
              [`${numerator}/${denominator}`]: `${round(width, 6)}%`,
            };
          }, {}),
        };
      }, {}),
      maxWidth: {
        screen: '100vw',
        limited: '1006px',
        '1/2': '50%',
      },
      transitionProperty: {
        stroke: 'stroke',
        'stroke-opacity': 'stroke-opacity',
      },
      transitionTimingFunction: {
        DEFAULT: 'ease',
      },
      gridTemplateRows: {
        auto: 'auto',
      },
      // The default preset already includes the primary font size scale (xs/sm/base/lg). The below
      // sizes are non-standard and should probably be migrated to gl-heading-* utils at some point.
      // In the meantime, we add them to GitLab's own Tailwind config.
      fontSize: {
        'size-h-display': '1.75rem',
        'size-h1': '1.4375rem',
        'size-h2': '1.1875rem',
        'size-h1-xl': '2rem',
        'size-h2-xl': '1.4375rem',
      },
    },
  },
  plugins: [
    plugin(gitLabUIUtilities),
    plugin(({ addUtilities }) => {
      addUtilities(utilities);
    }),
  ],
};
