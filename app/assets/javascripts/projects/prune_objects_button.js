import Vue from 'vue';
import PruneUnreachableObjectsButton from './prune_unreachable_objects_button.vue';

export default (selector = '#js-project-prune-unreachable-objects-button') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const { pruneObjectsPath, pruneObjectsDocPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(PruneUnreachableObjectsButton, {
        props: {
          pruneObjectsPath,
          pruneObjectsDocPath,
        },
      });
    },
  });
};
