import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import routes from './routes';
import CommentTemplatesApp from './components/app.vue';

export const initCommentTemplates = ({
  savedReplyType,
  path,
  fetchAllQuery,
  fetchSingleQuery,
  createMutation,
  deleteMutation,
  updateMutation,
}) => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const el = document.getElementById('js-comment-templates-root');
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  const router = new VueRouter({
    base: el.dataset.basePath,
    mode: 'history',
    routes,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    router,
    apolloProvider,
    provide: {
      path,
      namespaceId: el.dataset.namespaceId,
      savedReplyType,
      fetchAllQuery,
      fetchSingleQuery,
      createMutation,
      deleteMutation,
      updateMutation,
    },
    render(h) {
      return h(CommentTemplatesApp);
    },
  });
};
