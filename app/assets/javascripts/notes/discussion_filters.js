import Vue from 'vue';
import DiscussionFilter from './components/discussion_filter.vue';

export default (store) => {
  const discussionFilterEl = document.getElementById('js-vue-discussion-filter');

  if (discussionFilterEl) {
    const { defaultFilter, notesFilters } = discussionFilterEl.dataset;
    const filterValues = notesFilters ? JSON.parse(notesFilters) : {};
    const filters = Object.keys(filterValues).map((entry) => ({
      title: entry,
      value: filterValues[entry],
    }));
    const props = { filters };

    if (defaultFilter) {
      props.selectedValue = parseInt(defaultFilter, 10);
    }

    return new Vue({
      el: discussionFilterEl,
      name: 'DiscussionFilter',
      components: {
        DiscussionFilter,
      },
      store,
      render(createElement) {
        return createElement('discussion-filter', { props });
      },
    });
  }

  return null;
};
