import Vue from 'vue';
import { __ } from '~/locale';
import DiscussionFilter from './components/discussion_filter.vue';

export default (store) => {
  const discussionFilterEl = document.getElementById('js-vue-discussion-filter');

  if (discussionFilterEl) {
    const { defaultFilter } = discussionFilterEl.dataset;
    const defaultValue = defaultFilter ? parseInt(defaultFilter, 10) : null;

    // TODO fetch these values from backend
    const filterValues = [
      {
        title: __('Show all activity'),
        value: 0,
      },
      {
        title: __('Show comments only'),
        value: 1,
      },
    ];

    return new Vue({
      el: '#js-vue-discussion-filter',
      name: 'DiscussionFilter',
      components: {
        DiscussionFilter,
      },
      store,
      render(createElement) {
        return createElement('discussion-filter', {
          props: {
            filters: filterValues,
            defaultValue,
          },
        });
      },
    });
  }

  return null;
};
