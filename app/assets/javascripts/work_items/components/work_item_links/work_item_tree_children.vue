<script>
export default {
  components: {
    WorkItemLinkChild: () => import('./work_item_link_child.vue'),
  },
  props: {
    workItemType: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    children: {
      type: Array,
      required: false,
      default: () => [],
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  methods: {
    onClick(event, child) {
      // To avoid incorrect work item to be bubbled up
      // Assign the correct child item
      if (!event.childItem) {
        Object.assign(event, { childItem: child });
      }
      this.$emit('click', event);
    },
  },
};
</script>

<template>
  <div class="gl-ml-6" data-testid="tree-children">
    <work-item-link-child
      v-for="child in children"
      :key="child.id"
      :can-update="canUpdate"
      :issuable-gid="workItemId"
      :child-item="child"
      :work-item-type="workItemType"
      :show-labels="showLabels"
      @removeChild="$emit('removeChild', $event)"
      @click="onClick($event, child)"
    />
  </div>
</template>
