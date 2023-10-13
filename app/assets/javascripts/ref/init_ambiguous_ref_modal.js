import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import AmbiguousRefModal from './components/ambiguous_ref_modal.vue';
import { REF_TYPE_PARAM_NAME, TAG_REF_TYPE, BRANCH_REF_TYPE } from './constants';

export default (el = document.querySelector('#js-ambiguous-ref-modal')) => {
  const refType = getParameterByName(REF_TYPE_PARAM_NAME);
  const isRefTypeSet = refType === TAG_REF_TYPE || refType === BRANCH_REF_TYPE; // if ref_type is already set in the URL, we don't want to display the modal
  if (!el || isRefTypeSet || !parseBoolean(el.dataset.ambiguous)) return false;

  const { ref } = el.dataset;

  return new Vue({
    el,
    render(createElement) {
      return createElement(AmbiguousRefModal, { props: { refName: ref } });
    },
  });
};
