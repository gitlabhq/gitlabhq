/* eslint-disable no-unused-vars */

import Vue from 'vue';
import GroupsComponent from './components/groups.vue'

$(() => {
  const appEl = document.querySelector('#dashboard-group-app');

  const GroupsApp = new Vue({
    el: appEl,
    components: {
      'groups-component': GroupsComponent
    },
    render: createElement => createElement('groups-component'),
  });
});
