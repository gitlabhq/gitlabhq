const plugin = require('tailwindcss/plugin');
const tailwindDefaults = require('@gitlab/ui/tailwind.defaults');
const { tailwindCQsMQsPlugin } = require('@gitlab/ui/tailwind_cqs_mqs_plugin');

// Expands a link's click target to cover its closest positioned ancestor, which
// must therefore be positioned (for example with `gl-relative`).
const stretchedLinkPlugin = plugin(({ addUtilities }) => {
  addUtilities({
    '.stretched-link': {
      '&::after': {
        position: 'absolute',
        inset: '0',
        content: '""',
      },
    },
  });
});

/** @type {import('tailwindcss').Config} */
module.exports = {
  presets: [tailwindDefaults],
  darkMode: ['variant', ['&:where(.dark *)']],
  content: [
    './{ee,jh,}/app/assets/javascripts/**/*.{vue,js}',
    '!./app/assets/javascripts/locale/',
    './{ee,jh,}/app/helpers/**/*.rb',
    './{ee,jh,}/app/components/**/*.{haml,rb}',
    './{ee,jh,}/app/views/**/*.haml',
    './node_modules/@gitlab/ui/src/**/*.{vue,js}',
    './node_modules/@gitlab/duo-ui/dist/**/*.{vue,js}',
  ],
  blocklist: [
    // Prevents an irrelevant util from being generated.
    // In the long run, we'll look into disabling arbitrary values altogether, which should prevent
    // this from happening. For now, we are simply blocking the only problematic occurrence.
    '[link:page-slug]',
  ],
  corePlugins: {
    container: false,
  },
  plugins: [tailwindCQsMQsPlugin(true), stretchedLinkPlugin],
  theme: {
    extend: {
      containers: {
        sm: '576px',
        md: '768px',
        lg: '992px',
        xl: '1200px',
      },
    },
  },
};
