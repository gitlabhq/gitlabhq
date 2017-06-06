import Vue from 'vue';
import GroupFilterableList from './groups_filterable_list';
import GroupsComponent from './components/groups.vue';
import GroupFolder from './components/group_folder.vue';
import GroupItem from './components/group_item.vue';
import GroupsStore from './stores/groups_store';
import GroupsService from './services/groups_service';
import eventHub from './event_hub';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.querySelector('#dashboard-group-app');

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
        state: this.store.state,
      };
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
        getGroups.then((response) => {
          this.updateGroups(response.json(), parentGroup);
        })
        .catch(() => {
          // TODO: Handle error
        });

        return getGroups;
      },
      fetchPage(page, filterGroups, sort) {
        this.service.getGroups(null, page, filterGroups, sort)
          .then((response) => {
            this.updateGroups(response.json());
            this.updatePagination(response.headers);
            $.scrollTo(0);
          })
          .catch(() => {
            // TODO: Handle error
          });
      },
      toggleSubGroups(parentGroup = null) {
        if (!parentGroup.isOpen) {
          this.store.resetGroups(parentGroup);
          this.fetchGroups(parentGroup);
        }

        GroupsStore.toggleSubGroups(parentGroup);
      },
      leaveGroup(endpoint) {
        this.service.leaveGroup(endpoint)
          .then(() => {
            // TODO: Refresh?
          })
          .catch(() => {
            // TODO: Handle error
          });
      },
      updateGroups(groups, parentGroup) {
        this.store.setGroups(groups, parentGroup);
      },
      updatePagination(headers) {
        this.store.storePagination(headers);
      },
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

      eventHub.$on('fetchPage', this.fetchPage);
      eventHub.$on('toggleSubGroups', this.toggleSubGroups);
      eventHub.$on('leaveGroup', this.leaveGroup);
      eventHub.$on('updateGroups', this.updateGroups);
      eventHub.$on('updatePagination', this.updatePagination);
    },
    mounted() {
      this.fetchGroups()
        .then((response) => {
          this.updatePagination(response.headers);
        })
        .catch(() => {
          // TODO: Handle error
        });
    },
  });
});
