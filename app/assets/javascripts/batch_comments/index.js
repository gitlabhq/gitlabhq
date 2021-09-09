import Vue from 'vue';
import { mapActions, mapGetters } from 'vuex';
import store from '~/mr_notes/stores';

export const initReviewBar = () => {
  const el = document.getElementById('js-review-bar');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    components: {
      ReviewBar: () => import('./components/review_bar.vue'),
    },
    computed: {
      ...mapGetters('batchComments', ['draftsCount']),
    },
    mounted() {
      this.fetchDrafts();
    },
    methods: {
      ...mapActions('batchComments', ['fetchDrafts']),
    },
    render(createElement) {
      if (this.draftsCount === 0) return null;

      return createElement('review-bar');
    },
  });
};
