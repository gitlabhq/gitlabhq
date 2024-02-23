const tailwindDefaults = require('@gitlab/ui/tailwind.defaults');

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './{ee,}/app/assets/javascripts/**/*.{vue,js}',
    '!./app/assets/javascripts/locale/',
    './{ee,}/app/helpers/**/*.rb',
    './{ee,}/app/components/**/*.{haml,rb}',
    './{ee,}/app/views/**/*.haml',
    './node_modules/@gitlab/ui/dist/**/*.{vue,js}',
  ],
  presets: [tailwindDefaults],
  corePlugins: ['appearance', 'content', 'isolation', 'mixBlendMode', 'tableLayout', 'userSelect'],
  blocklist: [
    // Prevents an irrelevant util from being generated.
    // In the long run, we'll look into disabling arbitrary values altogether, which should prevent
    // this from happening. For now, we are simply blocking the only problematic occurrence.
    '[link:page-slug]',
  ],
};
