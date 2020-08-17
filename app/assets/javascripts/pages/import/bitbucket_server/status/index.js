import Vue from 'vue';
import { initStoreFromElement, initPropsFromElement } from '~/import_projects';
import BitbucketServerStatusTable from './components/bitbucket_server_status_table.vue';

document.addEventListener('DOMContentLoaded', () => {
  const mountElement = document.getElementById('import-projects-mount-element');
  if (!mountElement) return undefined;

  const store = initStoreFromElement(mountElement);
  const attrs = initPropsFromElement(mountElement);
  const { reconfigurePath } = mountElement.dataset;

  return new Vue({
    el: mountElement,
    store,
    render(createElement) {
      return createElement(BitbucketServerStatusTable, {
        attrs: { ...attrs, reconfigurePath },
      });
    },
  });
});
