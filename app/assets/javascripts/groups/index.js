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

  Vue.component('groups-component', GroupsComponent);
  Vue.component('group-folder', GroupFolder);
  Vue.component('group-item', GroupItem);

  return new Vue({
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
        let pageParam = null;

        if (parentGroup) {
          parentId = parentGroup.id;
        }

        pageParam = gl.utils.getParameterByName('page');

        if (pageParam) {
          page = pageParam;
        }

        getGroups = this.service.getGroups(parentId, page);
        getGroups.then((response) => {
          this.store.setGroups(response.json(), parentGroup);
        })
        .catch(() => {
          // TODO: Handle error
        });

        return getGroups;
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
    },
    beforeMount() {
      let groupFilterList = null;
      const form = document.querySelector('form#group-filter-form');
      const filter = document.querySelector('.js-groups-list-filter');
      const holder = document.querySelector('.js-groups-list-holder');

      const options = {
        form,
        filter,
        holder,
        store: this.store,
      };
      groupFilterList = new GroupFilterableList(options);
      groupFilterList.initSearch();

      eventHub.$on('toggleSubGroups', this.toggleSubGroups);
      eventHub.$on('leaveGroup', this.leaveGroup);
    },
    mounted() {
      this.fetchGroups()
        .then((response) => {
          this.store.storePagination(response.headers);
        })
        .catch(() => {
          // TODO: Handle error
        });
    },
  });
});
