import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import IssuableHeaderWarnings from './issuable_header_warnings.vue';

export default function issuableHeaderWarnings(store) {
  const el = document.getElementById('js-issuable-header-warnings');

  if (!el) {
    return false;
  }

  const { hidden } = el.dataset;

  return new Vue({
    el,
    store,
    provide: { hidden: parseBoolean(hidden) },
    render(createElement) {
      return createElement(IssuableHeaderWarnings);
    },
  });
}
