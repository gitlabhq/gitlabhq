import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import TodosApp from './components/todos_app.vue';

Vue.use(VueApollo);
Vue.use(VueRouter);

export default () => {
  const el = document.getElementById('js-todos-app-root');

  if (!el) {
    return false;
  }

  const { issuesDashboardPath, mergeRequestsDashboardPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      issuesDashboardPath,
      mergeRequestsDashboardPath,
    },
    router: new VueRouter({
      base: window.location.pathname,
      mode: 'history',
      routes: [{ path: '/' }],
    }),
    render(createElement) {
      return createElement(TodosApp);
    },
  });
};
