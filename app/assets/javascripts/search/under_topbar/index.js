import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import RefSelector from '~/ref/components/ref_selector.vue';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';

Vue.use(Translate);

export const initBlobRefSwitcher = () => {
  const el = document.getElementById('js-blob-ref-switcher');

  if (!el) return false;

  const { projectId, ref, fieldName } = el.dataset;

  return new Vue({
    el,
    name: 'GlobalSearchUnderTopbar',
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          value: ref,
        },
        on: {
          input(selected) {
            visitUrl(setUrlParams({ [fieldName]: selected }));
          },
        },
      });
    },
  });
};
