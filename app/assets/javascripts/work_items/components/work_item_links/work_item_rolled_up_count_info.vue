<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import {
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_REQUIREMENTS,
  WORK_ITEM_TYPE_NAME_TASK,
  WORK_ITEM_TYPE_NAME_TEST_CASE,
  WORK_ITEM_TYPE_NAME_TICKET,
} from '~/work_items/constants';

export default {
  closedCountsMap: {
    [WORK_ITEM_TYPE_NAME_EPIC]: s__('WorkItem|%{count} epics closed'),
    [WORK_ITEM_TYPE_NAME_INCIDENT]: s__('WorkItem|%{count} incidents closed'),
    [WORK_ITEM_TYPE_NAME_ISSUE]: s__('WorkItem|%{count} issues closed'),
    [WORK_ITEM_TYPE_NAME_KEY_RESULT]: s__('WorkItem|%{count} key results closed'),
    [WORK_ITEM_TYPE_NAME_OBJECTIVE]: s__('WorkItem|%{count} objectives closed'),
    [WORK_ITEM_TYPE_NAME_REQUIREMENTS]: s__('WorkItem|%{count} requirements closed'),
    [WORK_ITEM_TYPE_NAME_TASK]: s__('WorkItem|%{count} tasks closed'),
    [WORK_ITEM_TYPE_NAME_TEST_CASE]: s__('WorkItem|%{count} test cases closed'),
    [WORK_ITEM_TYPE_NAME_TICKET]: s__('WorkItem|%{count} tickets closed'),
  },
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
      <work-item-type-icon :work-item-type="rolledUpCount.workItemType.name" />
      <gl-sprintf :message="$options.closedCountsMap[rolledUpCount.workItemType.name]">
        <template #count>
          <span class="gl-font-bold">
            {{ rolledUpCount.countsByState.closed }}/{{ rolledUpCount.countsByState.all }}
          </span>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
