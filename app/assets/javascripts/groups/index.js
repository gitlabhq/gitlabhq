import Vue from 'vue';
import Translate from '../vue_shared/translate';
import GroupFilterableList from './groups_filterable_list';
import GroupsStore from './store/groups_store';
import GroupsService from './service/groups_service';

import groupsApp from './components/app.vue';
import groupFolderComponent from './components/group_folder.vue';
import groupItemComponent from './components/group_item.vue';
import { GROUPS_LIST_HOLDER_CLASS, CONTENT_LIST_CLASS } from './constants';

Vue.use(Translate);

export default (containerId = 'js-groups-tree', endpoint, action = '') => {
  const containerEl = document.getElementById(containerId);
  let dataEl;

  // Don't do anything if element doesn't exist (No groups)
  // This is for when the user enters directly to the page via URL
  if (!containerEl) {
    return;
  }

  const el = action ? containerEl.querySelector(GROUPS_LIST_HOLDER_CLASS) : containerEl;

  if (action) {
    dataEl = containerEl.querySelector(CONTENT_LIST_CLASS);
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
      const { dataset } = dataEl || this.$options.el;
      const hideProjects = dataset.hideProjects === 'true';
      const service = new GroupsService(endpoint || dataset.endpoint);
      const store = new GroupsStore(hideProjects);

      return {
        action,
        store,
        service,
        hideProjects,
        loading: true,
        containerId,
      };
    },
    beforeMount() {
      if (this.action) {
        return;
      }

      const { dataset } = dataEl || this.$options.el;
      let groupFilterList = null;
      const form = document.querySelector(dataset.formSel);
      const filter = document.querySelector(dataset.filterSel);
      const holder = document.querySelector(dataset.holderSel);

      const opts = {
        form,
        filter,
        holder,
        filterEndpoint: endpoint || dataset.endpoint,
        pagePath: dataset.path,
        dropdownSel: dataset.dropdownSel,
        filterInputField: 'filter',
        action: this.action,
      };

      groupFilterList = new GroupFilterableList(opts);
      groupFilterList.initSearch();
    },
    render(createElement) {
      return createElement('groups-app', {
        props: {
          action: this.action,
          store: this.store,
          service: this.service,
          hideProjects: this.hideProjects,
          containerId: this.containerId,
        },
      });
    },
  });
};
