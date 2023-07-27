import Vue from 'vue';
import WorkItemsListApp from '~/work_items/list/components/work_items_list_app.vue';

export const mountWorkItemsListApp = () => {
  const el = document.querySelector('.js-work-items-list-root');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'WorkItemsListRoot',
    render: (createComponent) => createComponent(WorkItemsListApp),
  });
};
