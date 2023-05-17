import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions, mapGetters } from 'vuex';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import store from '~/mr_notes/stores';

export const initReviewBar = ({ editorAiActions = [] } = {}) => {
  const el = document.getElementById('js-review-bar');

  if (!el) return;

  Vue.use(VueApollo);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    apolloProvider,
    components: {
      ReviewBar: () => import('./components/review_bar.vue'),
    },
    provide: {
      newCommentTemplatePath: el.dataset.newCommentTemplatePath,
      editorAiActions,
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
