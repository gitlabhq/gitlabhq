<script>
import GroupsStore from '../stores/groups_store';
import GroupsService from '../services/groups_service';
import eventHub from '../event_hub';

export default {
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

      this.fetchGroups();
    },
  },
};
</script>

<template>
  <div>
    <group-folder :groups="state.groups" />
  </div>
</template>
