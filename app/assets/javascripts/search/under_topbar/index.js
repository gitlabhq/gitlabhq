import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

Vue.use(Translate);

export const initBlobRefSwitcher = () => {
  const el = document.getElementById('js-blob-ref-switcher');

  if (!el) return false;

  const { projectId, ref, fieldName } = el.dataset;

  return initVueApp({
    el,
    name: 'GlobalSearchUnderTopbar',
    component: RefSelector,
    props: {
      projectId,
      value: ref,
    },
    events: {
      input(selected) {
        visitUrl(setUrlParams({ [fieldName]: selected }));
      },
    },
  });
};
