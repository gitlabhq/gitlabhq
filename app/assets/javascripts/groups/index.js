/* eslint-disable no-unused-vars */

import Vue from 'vue';
import GroupFilterableList from './groups_filterable_list';
import GroupsComponent from './components/groups.vue';
import GroupFolder from './components/group_folder.vue';
import GroupItem from './components/group_item.vue';
import GroupsStore from './stores/groups_store';
import GroupsService from './services/groups_service';
import eventHub from './event_hub';

$(() => {
  const appEl = document.querySelector('#dashboard-group-app');
  const form = document.querySelector('form#group-filter-form');
  const filter = document.querySelector('.js-groups-list-filter');
  const holder = document.querySelector('.js-groups-list-holder');

  const store = new GroupsStore();
  const service = new GroupsService(appEl.dataset.endpoint);

  Vue.component('groups-component', GroupsComponent);
  Vue.component('group-folder', GroupFolder);
  Vue.component('group-item', GroupItem);

  const GroupsApp = new Vue({
    el: appEl,
    data() {
      return {
        store,
        state: store.state,
      };
    },
    methods: {
      fetchGroups(parentGroup) {
        let parentId = null;

        if (parentGroup) {
          parentId = parentGroup.id;
        }

        service.getGroups(parentId)
          .then((response) => {
            store.setGroups(response.json(), parentGroup);
          })
          .catch(() => {
            // TODO: Handler error
          });
      },
      toggleSubGroups(parentGroup = null) {
        GroupsStore.toggleSubGroups(parentGroup);
        this.fetchGroups(parentGroup);
      },
    },
    created() {
      const groupFilterList = new GroupFilterableList(form, filter, holder, store);
      groupFilterList.initSearch();

      this.fetchGroups();

      eventHub.$on('toggleSubGroups', this.toggleSubGroups);
    },
  });
});
