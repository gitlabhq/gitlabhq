import Vue from 'vue';
import DiscussionFilter from './components/discussion_filter.vue';

export default store => {
  const discussionFilterEl = document.getElementById('js-vue-discussion-filter');

  if (discussionFilterEl) {
    const { defaultFilter, notesFilters } = discussionFilterEl.dataset;
    const selectedValue = defaultFilter ? parseInt(defaultFilter, 10) : null;
    const filterValues = notesFilters ? JSON.parse(notesFilters) : {};
    const filters = Object.keys(filterValues).map(entry => ({
      title: entry,
      value: filterValues[entry],
    }));

    return new Vue({
      el: discussionFilterEl,
      name: 'DiscussionFilter',
      components: {
        DiscussionFilter,
      },
      store,
      render(createElement) {
        return createElement('discussion-filter', {
          props: {
            filters,
            selectedValue,
          },
        });
      },
    });
  }

  return null;
};
