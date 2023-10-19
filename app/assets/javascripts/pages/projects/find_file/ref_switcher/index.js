import Vue from 'vue';
import { s__ } from '~/locale';
import Translate from '~/vue_shared/translate';
import RefSelector from '~/ref/components/ref_selector.vue';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from './ref_switcher_utils';

Vue.use(Translate);

const REF_SWITCH_HEADER = s__('FindFile|Switch branch/tag');

export default () => {
  const el = document.getElementById('js-blob-ref-switcher');
  if (!el) return false;

  const { projectId, ref, refType, namespace } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          value: refType ? joinPaths('refs', refType, ref) : ref,
          useSymbolicRefNames: Boolean(refType),
          translations: {
            dropdownHeader: REF_SWITCH_HEADER,
            searchPlaceholder: REF_SWITCH_HEADER,
          },
        },
        on: {
          input(selected) {
            visitUrl(generateRefDestinationPath(selected, namespace));
          },
        },
      });
    },
  });
};
