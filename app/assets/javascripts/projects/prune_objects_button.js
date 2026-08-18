import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import PruneUnreachableObjectsButton from './prune_unreachable_objects_button.vue';

export default (selector = '#js-project-prune-unreachable-objects-button') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const { pruneObjectsPath, pruneObjectsDocPath } = el.dataset;

  initVueApp({
    el,
    name: 'PruneUnreachableObjectsButtonRoot',
    component: PruneUnreachableObjectsButton,
    props: {
      pruneObjectsPath,
      pruneObjectsDocPath,
    },
  });
};
