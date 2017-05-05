import Vue from 'vue';
import GroupsStore from './stores/groups_store';

$(() => {
  const groupsStore = new GroupsStore();

  const GroupsApp = new Vue({
    el: document.querySelector('.js-groups-list-holder'),
    data: groupsStore,
  });
});
