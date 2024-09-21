<script>
import { GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import { TH_DESCRIPTION_TEST_ID, TH_TARGET_TEST_ID, TH_NEXT_TEST_ID } from '../../constants';
import PipelineScheduleActions from './cells/pipeline_schedule_actions.vue';
import PipelineScheduleLastPipeline from './cells/pipeline_schedule_last_pipeline.vue';
import PipelineScheduleNextRun from './cells/pipeline_schedule_next_run.vue';
import PipelineScheduleOwner from './cells/pipeline_schedule_owner.vue';
import PipelineScheduleTarget from './cells/pipeline_schedule_target.vue';

export default {
  fields: [
    {
      key: 'description',
      actualSortKey: 'DESCRIPTION',
      label: s__('PipelineSchedules|Description'),
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-6/20',
      sortable: true,
      thAttr: TH_DESCRIPTION_TEST_ID,
    },
    {
      key: 'interval',
      label: s__('PipelineSchedules|Interval'),
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-2/20',
    },
    {
      key: 'target',
      actualSortKey: 'REF',
      sortable: true,
      label: s__('PipelineSchedules|Target'),
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-2/20',
      thAttr: TH_TARGET_TEST_ID,
    },
    {
      key: 'pipeline',
      label: s__('PipelineSchedules|Last Pipeline'),
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-2/20',
    },
    {
      key: 'next',
      actualSortKey: 'NEXT_RUN_AT',
      label: s__('PipelineSchedules|Next Run'),
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-3/20',
      sortable: true,
      thAttr: TH_NEXT_TEST_ID,
    },
    {
      key: 'owner',
      label: s__('PipelineSchedules|Owner'),
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-2/20',
    },
    {
      key: 'actions',
      label: '',
      thClass: '!gl-border-t-0',
      columnClass: 'gl-w-3/20',
    },
  ],
  components: {
    GlTable,
    PipelineScheduleActions,
    PipelineScheduleLastPipeline,
    PipelineScheduleNextRun,
    PipelineScheduleOwner,
    PipelineScheduleTarget,
  },
  props: {
    schedules: {
      type: Array,
      required: true,
    },
    currentUser: {
      type: Object,
      required: true,
    },
    sortBy: {
      type: String,
      required: true,
    },
    sortDesc: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    fetchSortedData({ sortBy, sortDesc }) {
      const field = this.$options.fields.find(({ key }) => key === sortBy);
      const sortingDirection = sortDesc ? 'DESC' : 'ASC';

      if (!field?.actualSortKey) return;

      this.$emit('update-sorting', `${field.actualSortKey}_${sortingDirection}`, sortBy, sortDesc);
    },
  },
};
</script>

<template>
  <gl-table
    :fields="$options.fields"
    :items="schedules"
    :tbody-tr-attr="{ 'data-testid': 'pipeline-schedule-table-row' }"
    :empty-text="s__('PipelineSchedules|No pipeline schedules')"
    :sort-by="sortBy"
    :sort-desc="sortDesc"
    show-empty
    stacked="md"
    @sort-changed="fetchSortedData"
  >
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>

    <template #cell(description)="{ item }">
      <span data-testid="pipeline-schedule-description">
        {{ item.description }}
      </span>
    </template>

    <template #cell(interval)="{ item }">
      <span class="gl-mb-2 gl-block" data-testid="pipeline-schedule-cron">
        {{ item.cron }}
      </span>
      <span data-testid="pipeline-schedule-cron-timezone">
        {{ item.cronTimezone }}
      </span>
    </template>

    <template #cell(target)="{ item }">
      <pipeline-schedule-target :schedule="item" />
    </template>

    <template #cell(pipeline)="{ item }">
      <pipeline-schedule-last-pipeline :schedule="item" />
    </template>

    <template #cell(next)="{ item }">
      <pipeline-schedule-next-run :schedule="item" />
    </template>

    <template #cell(owner)="{ item }">
      <pipeline-schedule-owner :schedule="item" />
    </template>

    <template #cell(actions)="{ item }">
      <pipeline-schedule-actions
        :schedule="item"
        :current-user="currentUser"
        @showTakeOwnershipModal="$emit('showTakeOwnershipModal', $event)"
        @showDeleteModal="$emit('showDeleteModal', $event)"
        @playPipelineSchedule="$emit('playPipelineSchedule', $event)"
      />
    </template>
  </gl-table>
</template>
