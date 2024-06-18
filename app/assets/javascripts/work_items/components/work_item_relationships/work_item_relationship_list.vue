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
  <div data-testid="work-item-linked-items-list">
    <h4
      v-if="heading"
      data-testid="work-items-list-heading"
      class="gl-font-sm gl-font-semibold gl-text-gray-700 gl-mt-3 gl-mb-2 gl-ml-3"
    >
      {{ heading }}
    </h4>
    <div class="work-items-list-body">
      <ul ref="list" class="work-items-list content-list">
        <li
          v-for="linkedItem in linkedItems"
          :key="linkedItem.workItem.id"
          class="gl-pt-0! gl-pb-0! gl-border-b-0!"
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
  </div>
</template>
