import Vue from 'vue';
import SortDiscussion from './components/sort_discussion.vue';

export default store => {
  const el = document.getElementById('js-vue-sort-issue-discussions');

  if (!el) return null;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(SortDiscussion);
    },
  });
};
