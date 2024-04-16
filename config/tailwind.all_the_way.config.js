const path = require('path');
const plugin = require('tailwindcss/plugin');
const tailwindGitLabDefaults = require('./tailwind.config');

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
  ...tailwindGitLabDefaults,
  corePlugins: {
    /*
    We set background: none, Tailwind background-image: none...
    Probably compatible enough?
    We could also extend the theme, so that we use background: none in tailwind
     */
    backgroundImage: false,
    /*
    Our lineClamp also sets white-space: normal, which tailwind doesn't do, maybe we are okay?
     */
    lineClamp: false,
    /*
    Our opacity scale is 0 to 10, tailwind is 0, 100
    So:
    opacity-5 => opacity-50
    opacity-10 => opacity-100
     */
    opacity: false,
    /*
    outline-none in tailwind is 2px solid transparent, we have outline: none

    I assume that tailwind has it's reasons, and we probably could enable it
    after a UX check
     */
    outlineStyle: false,
    /*
    Our outline-0 removes the complete outline, while tailwind just sets the width to 0.
    Maybe compatible?
     */
    outlineWidth: false,
    /*
    Disable preflight styles so that `@tailwind base` compiles to CSS vars declarations without
    any of the resets which we don't need.
    More on this at https://tailwindcss.com/docs/preflight.
     */
    preflight: false,
  },
  theme: {
    // These extends probably should be moved to GitLab UI:
    extend: {
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
        DEFAULT: '0 1px 4px 0 rgba(#000, 0.3)',
        sm: '0 1px 2px var(--t-gray-a-08, #1f1e2414)',
        md: '0 2px 8px var(--t-gray-a-16, #1f1e2429), 0 0 2px var(--t-gray-a-16, #1f1e2429)',
        lg: '0 4px 12px var(--t-gray-a-16, #1f1e2429), 0 0 4px var(--t-gray-a-16, #1f1e2429)',
      },
    },
  },
  plugins: [
    plugin(({ addUtilities }) => {
      addUtilities(utilities);
    }),
  ],
};
