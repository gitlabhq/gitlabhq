import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import WorkItemsListApp from './components/work_items_list_app.vue';

export const mountWorkItemsListApp = () => {
  const el = document.querySelector('.js-work-items-list-root');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'WorkItemsListRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      fullPath: el.dataset.fullPath,
    },
    render: (createComponent) => createComponent(WorkItemsListApp),
  });
};
