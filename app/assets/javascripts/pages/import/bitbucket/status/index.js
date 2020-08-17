import Vue from 'vue';
import { initStoreFromElement, initPropsFromElement } from '~/import_projects';
import BitbucketStatusTable from '~/import_projects/components/bitbucket_status_table.vue';

document.addEventListener('DOMContentLoaded', () => {
  const mountElement = document.getElementById('import-projects-mount-element');
  if (!mountElement) return undefined;

  const store = initStoreFromElement(mountElement);
  const attrs = initPropsFromElement(mountElement);

  return new Vue({
    el: mountElement,
    store,
    render(createElement) {
      return createElement(BitbucketStatusTable, { attrs });
    },
  });
});
