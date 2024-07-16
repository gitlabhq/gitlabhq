const path = require('path');
const plugin = require('tailwindcss/plugin');
const tailwindDefaults = require('@gitlab/ui/tailwind.defaults');

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
  plugins: [
    plugin(({ addUtilities }) => {
      addUtilities(utilities);
    }),
  ],
};
