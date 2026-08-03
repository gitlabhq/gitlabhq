import $ from 'jquery';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNetwork from '~/behaviors/shortcuts/shortcuts_network';
import RefSelector from '~/ref/components/ref_selector.vue';
import RefSearchForm from '~/ref/components/ref_search_form.vue';

import Network from './network';

export const initRefSwitcher = () => {
  const refSwitcherEl = document.getElementById('js-graph-ref-switcher');
  const NETWORK_PATH_REGEX = /^(.*?)\/-\/network/g;

  if (!refSwitcherEl) return false;

  const { projectId, ref, networkPath } = refSwitcherEl.dataset;
  const networkRootPath = networkPath.match(NETWORK_PATH_REGEX)?.[0]; // gets the network path without the ref

  return initVueApp({
    el: refSwitcherEl,
    name: 'NetworkRefSelectorRoot',
    component: RefSelector,
    props: {
      projectId,
      value: ref,
    },
    events: {
      input(selectedRef) {
        visitUrl(joinPaths(networkRootPath, encodeURIComponent(selectedRef)));
      },
    },
  });
};

export const initRefSearchForm = () => {
  const refSearchEl = document.getElementById('js-ref-search-form');

  if (!refSearchEl) return false;

  const { networkPath } = refSearchEl.dataset;

  return initVueApp({
    el: refSearchEl,
    name: 'RefSearchFormRoot',
    component: RefSearchForm,
    props: {
      networkPath,
    },
  });
};

export const initNetworkGraph = () => {
  if (!$('.network-graph').length) return;

  const networkGraph = new Network({
    url: $('.network-graph').attr('data-url'),
    commit_url: $('.network-graph').attr('data-commit-url'),
    ref: $('.network-graph').attr('data-ref'),
    commit_id: $('.network-graph').attr('data-commit-id'),
  });

  addShortcutsExtension(ShortcutsNetwork, networkGraph.branch_graph);

  window.addEventListener('beforeunload', () => {
    networkGraph.destroy();
  });
};
