/* eslint-disable no-unused-vars */

import Vue from 'vue';
import GroupsList from '~/groups_list';
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
      fetchGroups() {
        service.getGroups()
          .then((response) => {
            store.setGroups(response.json());
          })
          .catch(() => {
            // TODO: Handler error
          });
      },
      toggleSubGroups(group) {
        GroupsStore.toggleSubGroups(group);

        this.fetchGroups();
      },
    },
    created() {
      const groupFilterList = new GroupsList(form, filter, holder, store);
      this.fetchGroups();

      eventHub.$on('toggleSubGroups', this.toggleSubGroups);
    },
  });
});
