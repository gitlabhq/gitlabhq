import Vue from 'vue';
import SuperSidebar from './components/super_sidebar.vue';

export const initSuperSidebar = () => {
  const el = document.querySelector('.js-super-sidebar');

  if (!el) return false;

  const { rootPath, toggleNewNavEndpoint } = el.dataset;

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    provide: {
      rootPath,
      toggleNewNavEndpoint,
    },
    render(h) {
      return h(SuperSidebar);
    },
  });
};
