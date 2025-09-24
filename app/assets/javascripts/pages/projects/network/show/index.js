import $ from 'jquery';
import Vue from 'vue';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNetwork from '~/behaviors/shortcuts/shortcuts_network';
import RefSelector from '~/ref/components/ref_selector.vue';
import RefSearchForm from '~/ref/components/ref_search_form.vue';
import Network from '../network';

const initRefSwitcher = () => {
  const refSwitcherEl = document.getElementById('js-graph-ref-switcher');
  const NETWORK_PATH_REGEX = /^(.*?)\/-\/network/g;

  if (!refSwitcherEl) return false;

  const { projectId, ref, networkPath } = refSwitcherEl.dataset;
  const networkRootPath = networkPath.match(NETWORK_PATH_REGEX)?.[0]; // gets the network path without the ref

  return new Vue({
    el: refSwitcherEl,
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          value: ref,
        },
        on: {
          input(selectedRef) {
            visitUrl(joinPaths(networkRootPath, encodeURIComponent(selectedRef)));
          },
        },
      });
    },
  });
};

export default function initRefSearchForm() {
  const refSearchEl = document.getElementById('js-ref-search-form');

  if (!refSearchEl) return false;

  const { networkPath } = refSearchEl.dataset;

  return new Vue({
    el: refSearchEl,
    render(h) {
      return h(RefSearchForm, {
        props: {
          networkPath,
        },
      });
    },
  });
}

initRefSwitcher();
initRefSearchForm();

(() => {
  let networkGraph = null;

  const initNetworkGraph = () => {
    if (!$('.network-graph').length) return;

    networkGraph = new Network({
      url: $('.network-graph').attr('data-url'),
      commit_url: $('.network-graph').attr('data-commit-url'),
      ref: $('.network-graph').attr('data-ref'),
      commit_id: $('.network-graph').attr('data-commit-id'),
    });

    addShortcutsExtension(ShortcutsNetwork, networkGraph.branch_graph);
  };

  const cleanupNetworkGraph = () => {
    if (networkGraph) {
      networkGraph.destroy();
      networkGraph = null;
    }
  };

  initNetworkGraph();

  window.addEventListener('beforeunload', cleanupNetworkGraph);
})();
