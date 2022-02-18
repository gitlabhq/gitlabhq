import Vue from 'vue';
import App from './components/app.vue';
import { createRouter } from './router';
import { createApolloProvider } from './graphql/provider';

export const initWorkItemsRoot = () => {
  const el = document.querySelector('#js-work-items');
  const { fullPath } = el.dataset;

  return new Vue({
    el,
    router: createRouter(el.dataset.fullPath),
    apolloProvider: createApolloProvider(),
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
