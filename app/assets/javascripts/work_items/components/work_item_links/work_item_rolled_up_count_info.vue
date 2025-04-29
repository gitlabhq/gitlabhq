<script>
import { s__ } from '~/locale';
import { sprintfWorkItem } from '~/work_items/constants';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  components: {
    WorkItemTypeIcon,
  },
  props: {
    filteredRollUpCountsByType: {
      type: Array,
      required: true,
    },
  },
  methods: {
    getItemsClosedLabel(workItemType) {
      return sprintfWorkItem(s__('WorkItem| %{workItemType}s closed'), workItemType);
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
      <work-item-type-icon :work-item-type="rolledUpCount.workItemType.name" />
      <span class="gl-font-bold"
        >{{ rolledUpCount.countsByState.closed }}/{{ rolledUpCount.countsByState.all }}</span
      >
      {{ getItemsClosedLabel(rolledUpCount.workItemType.name) }}
    </div>
  </div>
</template>
