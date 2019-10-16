import Vue from 'vue';

import SidebarApp from './components/sidebar_app.vue';

export default () => {
  const el = document.getElementById('js-vue-issuable-sidebar');

  if (!el) {
    return false;
  }

  const { sidebarStatusClass } = el.dataset;
  // An empty string is present when user is signed in.
  const signedIn = el.dataset.signedIn === '';

  return new Vue({
    el,
    components: { SidebarApp },
    render: createElement =>
      createElement('sidebar-app', {
        props: {
          signedIn,
          sidebarStatusClass,
        },
      }),
  });
};
