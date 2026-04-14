const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const COMPAT_DIR = path.join(ROOT, 'app/assets/javascripts/lib/utils/vue3compat');

const CONTEXT_ALIASES = {
  '@vue/compat': path.resolve(ROOT, 'node_modules/@vue/compat/dist/vue.runtime.esm-bundler.js'),
  vue: path.join(COMPAT_DIR, 'vue.js'),
  vuex: path.join(COMPAT_DIR, 'vuex.js'),
  'vue-router': path.join(COMPAT_DIR, 'vue_router.js'),
  'vue-apollo': path.join(COMPAT_DIR, 'vue_apollo.js'),
  'portal-vue': path.join(COMPAT_DIR, 'portal_vue_vue3.js'),
  'vue-demi': 'vue-demi/lib/v3/index.mjs',
  vuedraggable: '@gitlab/vuedraggable-vue3/src/vuedraggable.js',
  'vendor/vue-virtual-scroller': path.join(
    ROOT,
    'vendor/assets/javascripts/vue-virtual-scroller-vue3/src/index.js',
  ),
  'vue-virtual-scroll-list': path.join(
    ROOT,
    'app/assets/javascripts/vue_shared/vue_virtual_scroll_list_vue3.js',
  ),
};

const INFECTABLE_RE = /\.(js|mjs|vue)$/;
const INFECTION_BLOCKLIST = [
  // Global state vars should not be duplicated
  'app/assets/javascripts/lib/utils/breadcrumbs_state.js',
  'app/assets/javascripts/super_sidebar/state.js',
];

module.exports = { CONTEXT_ALIASES, INFECTABLE_RE, INFECTION_BLOCKLIST };
