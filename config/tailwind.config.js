const tailwindDefaults = require('@gitlab/ui/tailwind.defaults');

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
    './node_modules/@gitlab/ui/dist/**/*.{vue,js}',
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
};
