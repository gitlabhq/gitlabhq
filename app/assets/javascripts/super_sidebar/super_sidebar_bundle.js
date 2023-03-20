import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { initStatusTriggers } from '../header';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from './super_sidebar_collapsed_state_manager';
import SuperSidebar from './components/super_sidebar.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initSuperSidebar = () => {
  const el = document.querySelector('.js-super-sidebar');

  if (!el) return false;

  bindSuperSidebarCollapsedEvents();
  initSuperSidebarCollapsedState();

  const { rootPath, sidebar, toggleNewNavEndpoint } = el.dataset;

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider,
    provide: {
      rootPath,
      toggleNewNavEndpoint,
    },
    render(h) {
      return h(SuperSidebar, {
        props: {
          sidebarData: JSON.parse(sidebar),
        },
      });
    },
  });
};

requestIdleCallback(initStatusTriggers);
