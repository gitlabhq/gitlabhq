import Vue from 'vue';
import IssuableHeaderWarnings from './issuable_header_warnings.vue';

export default function issuableHeaderWarnings(store) {
  return new Vue({
    el: document.getElementById('js-issuable-header-warnings'),
    store,
    render(createElement) {
      return createElement(IssuableHeaderWarnings);
    },
  });
}
