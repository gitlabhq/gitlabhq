<script>
import AssigneesListItem from './assignees_list_item.vue';
import MilestoneListItem from './milestones_list_item.vue';

export default {
  props: {
    items: {
      type: Array,
      required: true,
    },
    listType: {
      type: String,
      required: true,
    },
  },
  computed: {
    listContentComponent() {
      return this.listType === 'assignees' ? AssigneesListItem : MilestoneListItem;
    },
  },
  methods: {
    handleItemClick(item) {
      this.$emit('onItemSelect', item);
    },
  },
};
</script>

<template>
  <div class="dropdown-content">
    <ul>
      <component
        v-for="item in items"
        :is="listContentComponent"
        :key="item.id"
        :item="item"
        @onItemSelect="handleItemClick"
      />
    </ul>
  </div>
</template>
