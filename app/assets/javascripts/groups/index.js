/* eslint-disable no-unused-vars */

import Vue from 'vue';
import GroupsStore from './stores/groups_store';
import GroupsService from './services/groups_service';

$(() => {
  const appEl = document.querySelector('.js-groups-list-holder');

  const groupsStore = new GroupsStore();
  const groupsService = new GroupsService(appEl.dataset.endpoint);

  const GroupsApp = new Vue({
    el: appEl,
    data: groupsStore,
    mounted() {
      groupsService.getGroups()
        .then((response) => {
          this.groups = response.json();
        })
        .catch(() => {
          // TODO: Handle error
        });
    },
  });
});
