import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import UserCallout from '~/user_callout';
import GroupItemComponent from 'jh_else_ce/groups/components/group_item.vue';
import Translate from '../vue_shared/translate';

import GroupsApp from './components/app.vue';
import GroupFolderComponent from './components/group_folder.vue';
import GroupFilterableList from './groups_filterable_list';
import GroupsService from './service/groups_service';
import GroupsStore from './store/groups_store';

Vue.use(Translate);

export default (EmptyStateComponent) => {
  const el = document.getElementById('js-groups-tree');

  // eslint-disable-next-line no-new
  new UserCallout();

  if (!el) {
    return;
  }

  Vue.component('GroupFolder', GroupFolderComponent);
  Vue.component('GroupItem', GroupItemComponent);

  Vue.use(GlToast);

  const { dataset } = el;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      GroupsApp,
    },
    provide() {
      const { groupsEmptyStateIllustration } = dataset;

      return { groupsEmptyStateIllustration };
    },
    data() {
      const showSchemaMarkup = parseBoolean(dataset.showSchemaMarkup);
      const service = new GroupsService(dataset.endpoint);
      const store = new GroupsStore({ hideProjects: true, showSchemaMarkup });

      return {
        store,
        service,
        loading: true,
      };
    },
    beforeMount() {
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
        action: '',
      };

      groupFilterList = new GroupFilterableList(opts);
      groupFilterList.initSearch();
    },
    render(createElement) {
      return createElement('groups-app', {
        props: {
          store: this.store,
          service: this.service,
        },
        scopedSlots: {
          'empty-state': () => createElement(EmptyStateComponent),
        },
      });
    },
  });
};
