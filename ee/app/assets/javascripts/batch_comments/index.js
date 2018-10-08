import Vue from 'vue';
import { mapState, mapActions } from 'vuex';
import store from '~/mr_notes/stores';
import ReviewBar from './components/review_bar.vue';

// eslint-disable-next-line import/prefer-default-export
export const initReviewBar = () => {
  const el = document.getElementById('js-review-bar');

  if (el) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      computed: {
        ...mapState('batchComments', ['withBatchComments']),
      },
      created() {
        this.enableBatchComments();
      },
      mounted() {
        this.fetchDrafts();
      },
      methods: {
        ...mapActions('batchComments', ['fetchDrafts', 'enableBatchComments']),
      },
      render(createElement) {
        if (this.withBatchComments) {
          return createElement(ReviewBar);
        }

        return null;
      },
    });
  }
};
