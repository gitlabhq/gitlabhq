import Vue from 'vue';
import { mapActions } from 'vuex';
import store from '~/mr_notes/stores';
import ReviewBar from './components/review_bar.vue';

export const initReviewBar = () => {
  const el = document.getElementById('js-review-bar');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    mounted() {
      this.fetchDrafts();
    },
    methods: {
      ...mapActions('batchComments', ['fetchDrafts']),
    },
    render(createElement) {
      return createElement(ReviewBar);
    },
  });
};
