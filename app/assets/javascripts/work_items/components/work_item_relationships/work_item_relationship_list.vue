<script>
import WorkItemLinkChildContents from '../shared/work_item_link_child_contents.vue';

export default {
  components: {
    WorkItemLinkChildContents,
  },
  props: {
    linkedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    heading: {
      type: String,
      required: true,
    },
    canUpdate: {
      type: Boolean,
      required: true,
    },
    showLabels: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div data-testid="work-item-linked-items-list" class="gl-p-3">
    <h3
      v-if="heading"
      data-testid="work-items-list-heading"
      class="gl-mb-0 gl-mt-0 gl-block gl-rounded-base gl-bg-gray-50 gl-px-3 gl-py-2 gl-text-sm gl-font-semibold gl-text-subtle"
    >
      {{ heading }}
    </h3>
    <ul ref="list" class="work-items-list content-list">
      <li
        v-for="linkedItem in linkedItems"
        :key="linkedItem.workItem.id"
        data-testid="link-child-contents-container"
        class="!gl-border-x-0 !gl-border-b-1 !gl-border-t-0 !gl-border-solid !gl-border-gray-50 !gl-px-0 !gl-py-2 last:!gl-border-b-0"
      >
        <work-item-link-child-contents
          :child-item="linkedItem.workItem"
          :can-update="canUpdate"
          :show-labels="showLabels"
          :work-item-full-path="workItemFullPath"
          @click="$emit('showModal', { event: $event, child: linkedItem.workItem })"
          @removeChild="$emit('removeLinkedItem', linkedItem.workItem)"
        />
      </li>
    </ul>
  </div>
</template>
