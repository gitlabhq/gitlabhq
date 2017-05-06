<script>
import GroupsStore from '../stores/groups_store';
import GroupsService from '../services/groups_service';
import GroupItem from '../components/group_item.vue';

export default {
  components: {
    'group-item': GroupItem,
  },

  data() {
    const store = new GroupsStore();

    return {
      store,
      state: store.state,
    }
  },

  created() {
    const appEl = document.querySelector('#dashboard-group-app');

    this.service = new GroupsService(appEl.dataset.endpoint);
    this.fetchGroups();
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
  }
};
</script>

<template>
  <table class="table table-bordered">
    <group-item :group="group" v-for="group in state.groups" />
  </table>
</template>
