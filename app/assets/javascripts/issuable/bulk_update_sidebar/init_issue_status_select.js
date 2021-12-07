import Vue from 'vue';
import StatusSelect from './components/status_select.vue';

export default function initIssueStatusSelect() {
  const el = document.querySelector('.js-issue-status');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(h) {
      return h(StatusSelect);
    },
  });
}
