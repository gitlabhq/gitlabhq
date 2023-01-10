<script>
import { createAlert } from '~/flash';
import { s__ } from '~/locale';

import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';

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
  methods: {
    async updateWorkItem(childId) {
      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: { input: { id: childId, hierarchyWidget: { parentId: null } } },
        });
        this.$emit('removeChild');
      } catch (error) {
        createAlert({
          message: s__('Hierarchy|Something went wrong while removing a child item.'),
          captureError: true,
          error,
        });
      }
    },
  },
};
</script>

<template>
  <div class="gl-ml-6">
    <work-item-link-child
      v-for="child in children"
      :key="child.id"
      :project-path="projectPath"
      :can-update="canUpdate"
      :issuable-gid="workItemId"
      :child-item="child"
      :work-item-type="workItemType"
      @removeChild="updateWorkItem"
      @click="$emit('click', Object.assign($event, { childItem: child }))"
    />
  </div>
</template>
