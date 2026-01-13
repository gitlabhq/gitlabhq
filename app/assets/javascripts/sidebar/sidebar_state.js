import Vue from 'vue';

export const sidebarState = Vue.observable({
  issuable: {},
  loading: false,
  initialLoading: true,
  drawerOpen: false,
});
