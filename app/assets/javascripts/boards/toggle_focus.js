import Vue from 'vue';
import ToggleFocus from './components/toggle_focus.vue';

export default () => {
  const issueBoardsContentSelector = '.content-wrapper > .js-focus-mode-board';

  return new Vue({
    el: '#js-toggle-focus-btn',
    render(h) {
      return h(ToggleFocus, {
        props: {
          issueBoardsContentSelector,
        },
      });
    },
  });
};
