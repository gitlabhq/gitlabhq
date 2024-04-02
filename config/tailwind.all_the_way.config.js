// const plugin = require('tailwindcss/plugin');
const tailwindGitLabDefaults = require('./tailwind.config');
// const utilities = require('./helpers/tailwind/css_in_js');

const { content, ...remainingConfig } = tailwindGitLabDefaults;

/** @type {import('tailwindcss').Config} */
module.exports = {
  content,
  ...remainingConfig,
  // This will be filled with life in a follow-up MR
};
