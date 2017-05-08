<script>
import GroupsStore from '../stores/groups_store';
import GroupsService from '../services/groups_service';
import GroupItem from '../components/group_item.vue';
import eventHub from '../event_hub';

export default {
  components: {
    'group-item': GroupItem,
  },

  data() {
    const store = new GroupsStore();

    return {
      store,
      state: store.state,
    };
  },

  created() {
    const appEl = document.querySelector('#dashboard-group-app');

    this.service = new GroupsService(appEl.dataset.endpoint);
    this.fetchGroups();

    eventHub.$on('toggleSubGroups', this.toggleSubGroups);
  },

  methods: {
    fetchGroups() {
      this.service.getGroups()
        .then((response) => {
          this.store.setGroups(response.json());
        })
        .catch(() => {
          // TODO: Handler error
        });
    },
    toggleSubGroups(group) {
      GroupsStore.toggleSubGroups(group);
    },
  },
};
</script>

<template>
  <table class="table table-bordered">
    <template v-for="group in state.groups">
      <tr is="group-item" :group="group" />
      <tr v-if="group.isOpen">
        <td>sub groups for {{group.name}}</td>
        <td></td>
      </tr>
    </template>
  </table>
</template>
