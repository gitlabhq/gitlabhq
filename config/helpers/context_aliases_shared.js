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

// Infectable despite the scanner marking them clean, so a Vue 3 importer gets a
// Vue 3 copy and infection continues past them. Otherwise the subtree below
// reverts to Vue 2 inside a Vue 3 page. Exact paths, one entry per edition.
// https://gitlab.com/gitlab-org/gitlab/-/work_items/625296
const INFECTION_FORCELIST = [
  'app/assets/javascripts/issuable/index.js',
  'app/assets/javascripts/mr_notes/mount_app.js',
  'app/assets/javascripts/sidebar/sidebar_bundle.js',
  'ee/app/assets/javascripts/hand_raise_leads/hand_raise_lead/index.js',
];

module.exports = {
  CONTEXT_ALIASES,
  INFECTABLE_RE,
  INFECTION_BLOCKLIST,
  INFECTION_FORCELIST,
};
