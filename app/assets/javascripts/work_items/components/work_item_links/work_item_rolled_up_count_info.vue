<script>
import { GlSprintf } from '@gitlab/ui';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  components: {
    GlSprintf,
    WorkItemTypeIcon,
  },
  props: {
    filteredRollUpCountsByType: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div
    v-if="filteredRollUpCountsByType.length > 0"
    class="gl-flex gl-flex-col gl-gap-y-2"
    data-testid="rolled-up-count-info"
  >
    <div
      v-for="rolledUpCount in filteredRollUpCountsByType"
      :key="rolledUpCount.workItemType.name"
      data-testid="rolled-up-type-info"
    >
      <work-item-type-icon
        :work-item-type="rolledUpCount.workItemType.name"
        :type-icon-name="rolledUpCount.workItemType.iconName"
      />
      <gl-sprintf :message="s__('WorkItem|%{workItemType}: %{count} closed')">
        <template #workItemType>{{ rolledUpCount.workItemType.name }}</template>
        <template #count>
          <span class="gl-font-bold">
            {{ rolledUpCount.countsByState.closed }}/{{ rolledUpCount.countsByState.all }}
          </span>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
