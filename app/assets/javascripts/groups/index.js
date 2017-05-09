/* eslint-disable no-unused-vars */

import Vue from 'vue';
import GroupsComponent from './components/groups.vue';
import GroupFolder from './components/group_folder.vue';
import GroupItem from './components/group_item.vue';

$(() => {
  const appEl = document.querySelector('#dashboard-group-app');

  Vue.component('groups-component', GroupsComponent);
  Vue.component('group-folder', GroupFolder);
  Vue.component('group-item', GroupItem);

  const GroupsApp = new Vue({
    el: appEl,
    render: createElement => createElement('groups-component'),
  });
});
