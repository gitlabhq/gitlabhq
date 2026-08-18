import Vue from 'vue';
import { s__ } from '~/locale';
import Translate from '~/vue_shared/translate';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from './ref_switcher_utils';

Vue.use(Translate);

const REF_SWITCH_HEADER = s__('FindFile|Switch branch/tag');

export function initFindFileRefSwitcher() {
  const el = document.getElementById('js-blob-ref-switcher');
  if (!el) return false;

  const { projectId, ref, refType, namespace } = el.dataset;

  return initVueApp({
    el,
    name: 'FindFileRefSelectorRoot',
    component: RefSelector,
    props: {
      projectId,
      value: refType ? joinPaths('refs', refType, ref) : ref,
      useSymbolicRefNames: Boolean(refType),
      translations: {
        dropdownHeader: REF_SWITCH_HEADER,
        searchPlaceholder: REF_SWITCH_HEADER,
      },
    },
    events: {
      input(selected) {
        visitUrl(generateRefDestinationPath(selected, namespace));
      },
    },
  });
}
