import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GroupFilter from './components/group_filter.vue';
import ProjectFilter from './components/project_filter.vue';

Vue.use(Translate);

const mountSearchableDropdown = (store, { id, component }) => {
  const el = document.getElementById(id);

  if (!el) {
    return false;
  }

  let { initialData } = el.dataset;

  initialData = JSON.parse(initialData);

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(component, {
        props: {
          initialData,
        },
      });
    },
  });
};

const searchableDropdowns = [
  {
    id: 'js-search-group-dropdown',
    component: GroupFilter,
  },
  {
    id: 'js-search-project-dropdown',
    component: ProjectFilter,
  },
];

export const initTopbar = (store) =>
  searchableDropdowns.map((dropdown) => mountSearchableDropdown(store, dropdown));
