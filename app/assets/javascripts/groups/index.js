/* global Flash */

import Vue from 'vue';
import GroupFilterableList from './groups_filterable_list';
import GroupsComponent from './components/groups.vue';
import GroupFolder from './components/group_folder.vue';
import GroupItem from './components/group_item.vue';
import GroupsStore from './stores/groups_store';
import GroupsService from './services/groups_service';
import eventHub from './event_hub';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('dashboard-group-app');

  // Don't do anything if element doesn't exist (No groups)
  // This is for when the user enters directly to the page via URL
  if (!el) {
    return;
  }

  Vue.component('groups-component', GroupsComponent);
  Vue.component('group-folder', GroupFolder);
  Vue.component('group-item', GroupItem);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    data() {
      this.store = new GroupsStore();
      this.service = new GroupsService(el.dataset.endpoint);

      return {
        store: this.store,
        isLoading: true,
        state: this.store.state,
        loading: true,
      };
    },
    computed: {
      isEmpty() {
        return Object.keys(this.state.groups).length === 0;
      },
    },
    methods: {
      fetchGroups(parentGroup) {
        let parentId = null;
        let getGroups = null;
        let page = null;
        let sort = null;
        let pageParam = null;
        let sortParam = null;
        let filterGroups = null;
        let filterGroupsParam = null;

        if (parentGroup) {
          parentId = parentGroup.id;
        } else {
          this.isLoading = true;
        }

        pageParam = gl.utils.getParameterByName('page');
        if (pageParam) {
          page = pageParam;
        }

        filterGroupsParam = gl.utils.getParameterByName('filter_groups');
        if (filterGroupsParam) {
          filterGroups = filterGroupsParam;
        }

        sortParam = gl.utils.getParameterByName('sort');
        if (sortParam) {
          sort = sortParam;
        }

        getGroups = this.service.getGroups(parentId, page, filterGroups, sort);
        getGroups
          .then(response => response.json())
          .then((response) => {
            this.isLoading = false;

            this.updateGroups(response, parentGroup);
          })
          .catch(this.handleErrorResponse);

        return getGroups;
      },
      fetchPage(page, filterGroups, sort) {
        this.isLoading = true;

        return this.service
          .getGroups(null, page, filterGroups, sort)
          .then((response) => {
            this.isLoading = false;
            $.scrollTo(0);

            const currentPath = gl.utils.mergeUrlParams({ page }, window.location.href);
            window.history.replaceState({
              page: currentPath,
            }, document.title, currentPath);

            return response.json().then((data) => {
              this.updateGroups(data);
              this.updatePagination(response.headers);
            });
          })
          .catch(this.handleErrorResponse);
      },
      toggleSubGroups(parentGroup = null) {
        if (!parentGroup.isOpen) {
          this.store.resetGroups(parentGroup);
          this.fetchGroups(parentGroup);
        }

        this.store.toggleSubGroups(parentGroup);
      },
      leaveGroup(group, collection) {
        this.service.leaveGroup(group.leavePath)
          .then(resp => resp.json())
          .then((response) => {
            $.scrollTo(0);

            this.store.removeGroup(group, collection);

            // eslint-disable-next-line no-new
            new Flash(response.notice, 'notice');
          })
          .catch((error) => {
            let message = 'An error occurred. Please try again.';

            if (error.status === 403) {
              message = 'Failed to leave the group. Please make sure you are not the only owner';
            }

            // eslint-disable-next-line no-new
            new Flash(message);
          });
      },
      updateGroups(groups, parentGroup) {
        this.store.setGroups(groups, parentGroup);
      },
      updatePagination(headers) {
        this.store.storePagination(headers);
      },
      handleErrorResponse() {
        this.isLoading = false;
        $.scrollTo(0);

        // eslint-disable-next-line no-new
        new Flash('An error occurred. Please try again.');
      },
    },
    created() {
      eventHub.$on('fetchPage', this.fetchPage);
      eventHub.$on('toggleSubGroups', this.toggleSubGroups);
      eventHub.$on('leaveGroup', this.leaveGroup);
      eventHub.$on('updateGroups', this.updateGroups);
      eventHub.$on('updatePagination', this.updatePagination);
    },
    beforeMount() {
      let groupFilterList = null;
      const form = document.querySelector('form#group-filter-form');
      const filter = document.querySelector('.js-groups-list-filter');
      const holder = document.querySelector('.js-groups-list-holder');

      const opts = {
        form,
        filter,
        holder,
        filterEndpoint: el.dataset.endpoint,
        pagePath: el.dataset.path,
      };

      groupFilterList = new GroupFilterableList(opts);
      groupFilterList.initSearch();
    },
    mounted() {
      this.fetchGroups()
        .then((response) => {
          this.updatePagination(response.headers);
          this.isLoading = false;
        })
        .catch(this.handleErrorResponse);
    },
    beforeDestroy() {
      eventHub.$off('fetchPage', this.fetchPage);
      eventHub.$off('toggleSubGroups', this.toggleSubGroups);
      eventHub.$off('leaveGroup', this.leaveGroup);
      eventHub.$off('updateGroups', this.updateGroups);
      eventHub.$off('updatePagination', this.updatePagination);
    },
  });
});
