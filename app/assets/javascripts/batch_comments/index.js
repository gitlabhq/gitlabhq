import Vue from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import store from '~/mr_notes/stores';
import { pinia } from '~/pinia/instance';

export const initReviewBar = () => {
  const el = document.getElementById('js-review-bar');

  if (!el) return;

  Vue.use(VueApollo);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    pinia,
    apolloProvider,
    components: {
      ReviewBar: () => import('./components/review_bar.vue'),
    },
    provide: {
      newCommentTemplatePaths: JSON.parse(el.dataset.newCommentTemplatePaths),
      canSummarize: parseBoolean(el.dataset.canSummarize),
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
