import Vue from 'vue';
import DiscussionFilter from './components/discussion_filter.vue';

export default (store) => {
  const discussionFilterEl = document.getElementById('js-vue-discussion-filter');

  if (discussionFilterEl) {
    const { defaultFilter, notesFilters } = discussionFilterEl.dataset;
    const defaultValue = defaultFilter ? parseInt(defaultFilter, 10) : null;
    const filterValues = notesFilters ? JSON.parse(notesFilters) : {};
    const filters = Object.entries(filterValues).map(entry =>
      ({ title: entry[0], value: entry[1] }));

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
            defaultValue,
          },
        });
      },
    });
  }

  return null;
};
