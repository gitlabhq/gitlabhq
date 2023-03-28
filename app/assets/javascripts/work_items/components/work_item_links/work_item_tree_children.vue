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
    projectPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-ml-6" data-testid="tree-children">
    <work-item-link-child
      v-for="child in children"
      :key="child.id"
      :project-path="projectPath"
      :can-update="canUpdate"
      :issuable-gid="workItemId"
      :child-item="child"
      :work-item-type="workItemType"
      @removeChild="$emit('removeChild', child.id)"
      @click="$emit('click', Object.assign($event, { childItem: child }))"
    />
  </div>
</template>
