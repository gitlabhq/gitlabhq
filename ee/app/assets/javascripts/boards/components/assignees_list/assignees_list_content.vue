<script>
import AssigneesListItem from './assignees_list_item.vue';

export default {
  components: {
    AssigneesListItem,
  },
  props: {
    assignees: {
      type: Array,
      required: true,
    },
  },
  methods: {
    handleItemClick(assignee) {
      this.$emit('onItemSelect', assignee);
    },
  },
};
</script>

<template>
  <div class="dropdown-content">
    <ul>
      <assignees-list-item
        v-for="assignee in assignees"
        :key="assignee.id"
        :assignee="assignee"
        @onItemSelect="handleItemClick"
      />
    </ul>
  </div>
</template>
