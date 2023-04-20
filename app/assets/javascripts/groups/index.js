import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserCallout from '~/user_callout';
import Translate from '../vue_shared/translate';

import GroupsApp from './components/app.vue';
import GroupFolderComponent from './components/group_folder.vue';
import GroupItemComponent from './components/group_item.vue';
import { GROUPS_LIST_HOLDER_CLASS, CONTENT_LIST_CLASS } from './constants';
import GroupFilterableList from './groups_filterable_list';
import GroupsService from './service/groups_service';
import GroupsStore from './store/groups_store';

Vue.use(Translate);

export default (containerId = 'js-groups-tree', endpoint, action = '') => {
  const containerEl = document.getElementById(containerId);
  let dataEl;

  // eslint-disable-next-line no-new
  new UserCallout();

  // Don't do anything if element doesn't exist (No groups)
  // This is for when the user enters directly to the page via URL
  if (!containerEl) {
    return;
  }

  const el = action ? containerEl.querySelector(GROUPS_LIST_HOLDER_CLASS) : containerEl;

  if (action) {
    dataEl = containerEl.querySelector(CONTENT_LIST_CLASS);
  }

  Vue.component('GroupFolder', GroupFolderComponent);
  Vue.component('GroupItem', GroupItemComponent);

  Vue.use(GlToast);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      GroupsApp,
    },
    provide() {
      const {
        dataset: {
          newSubgroupPath,
          newProjectPath,
          newSubgroupIllustration,
          newProjectIllustration,
          emptyProjectsIllustration,
          emptySubgroupIllustration,
          canCreateSubgroups,
          canCreateProjects,
          currentGroupVisibility,
        },
      } = this.$options.el;

      return {
        newSubgroupPath,
        newProjectPath,
        newSubgroupIllustration,
        newProjectIllustration,
        emptyProjectsIllustration,
        emptySubgroupIllustration,
        canCreateSubgroups: parseBoolean(canCreateSubgroups),
        canCreateProjects: parseBoolean(canCreateProjects),
        currentGroupVisibility,
      };
    },
    data() {
      const { dataset } = dataEl || this.$options.el;
      const hideProjects = parseBoolean(dataset.hideProjects);
      const showSchemaMarkup = parseBoolean(dataset.showSchemaMarkup);
      const renderEmptyState = parseBoolean(dataset.renderEmptyState);
      const service = new GroupsService(endpoint || dataset.endpoint);
      const store = new GroupsStore({ hideProjects, showSchemaMarkup });

      return {
        action,
        store,
        service,
        hideProjects,
        renderEmptyState,
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
          renderEmptyState: this.renderEmptyState,
          containerId: this.containerId,
        },
      });
    },
  });
};
