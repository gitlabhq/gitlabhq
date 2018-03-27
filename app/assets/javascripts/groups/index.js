import Vue from 'vue';
import Translate from '../vue_shared/translate';
import GroupFilterableList from './groups_filterable_list';
import GroupsStore from './store/groups_store';
import GroupsService from './service/groups_service';

import groupsApp from './components/app.vue';
import groupFolderComponent from './components/group_folder.vue';
import groupItemComponent from './components/group_item.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-groups-tree');

  // Don't do anything if element doesn't exist (No groups)
  // This is for when the user enters directly to the page via URL
  if (!el) {
    return;
  }

  Vue.component('group-folder', groupFolderComponent);
  Vue.component('group-item', groupItemComponent);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      groupsApp,
    },
    data() {
      const dataset = this.$options.el.dataset;
      const hideProjects = dataset.hideProjects === 'true';
      const store = new GroupsStore(hideProjects);
      const service = new GroupsService(dataset.endpoint);

      return {
        store,
        service,
        hideProjects,
        loading: true,
      };
    },
    beforeMount() {
      const dataset = this.$options.el.dataset;
      let groupFilterList = null;
      const form = document.querySelector(dataset.formSel);
      const filter = document.querySelector(dataset.filterSel);
      const holder = document.querySelector(dataset.holderSel);

      const opts = {
        form,
        filter,
        holder,
        filterEndpoint: dataset.endpoint,
        pagePath: dataset.path,
        dropdownSel: dataset.dropdownSel,
        filterInputField: 'filter',
      };

      groupFilterList = new GroupFilterableList(opts);
      groupFilterList.initSearch();
    },
    render(createElement) {
      return createElement('groups-app', {
        props: {
          store: this.store,
          service: this.service,
          hideProjects: this.hideProjects,
        },
      });
    },
  });
};
