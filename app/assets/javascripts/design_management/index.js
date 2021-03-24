import Vue from 'vue';
import App from './components/app.vue';
import apolloProvider from './graphql';
import activeDiscussionQuery from './graphql/queries/active_discussion.query.graphql';
import createRouter from './router';

export default () => {
  const el = document.querySelector('.js-design-management');
  const { issueIid, projectPath, issuePath } = el.dataset;
  const router = createRouter(issuePath);

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: activeDiscussionQuery,
    data: {
      activeDiscussion: {
        __typename: 'ActiveDiscussion',
        id: null,
        source: null,
      },
    },
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    provide: {
      projectPath,
      issueIid,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
