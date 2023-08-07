<script>
import { GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import PipelineScheduleActions from './cells/pipeline_schedule_actions.vue';
import PipelineScheduleLastPipeline from './cells/pipeline_schedule_last_pipeline.vue';
import PipelineScheduleNextRun from './cells/pipeline_schedule_next_run.vue';
import PipelineScheduleOwner from './cells/pipeline_schedule_owner.vue';
import PipelineScheduleTarget from './cells/pipeline_schedule_target.vue';

export default {
  i18n: {
    emptyText: s__('PipelineSchedules|No pipeline schedules'),
  },
  fields: [
    {
      key: 'description',
      label: s__('PipelineSchedules|Description'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-40p',
    },
    {
      key: 'target',
      label: s__('PipelineSchedules|Target'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-10p',
    },
    {
      key: 'pipeline',
      label: s__('PipelineSchedules|Last Pipeline'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-10p',
    },
    {
      key: 'next',
      label: s__('PipelineSchedules|Next Run'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-15p',
    },
    {
      key: 'owner',
      label: s__('PipelineSchedules|Owner'),
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-10p',
    },
    {
      key: 'actions',
      label: '',
      thClass: 'gl-border-t-none!',
      columnClass: 'gl-w-15p',
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
  },
};
</script>

<template>
  <gl-table
    :fields="$options.fields"
    :items="schedules"
    :tbody-tr-attr="{ 'data-testid': 'pipeline-schedule-table-row' }"
    :empty-text="$options.i18n.emptyText"
    show-empty
    stacked="md"
  >
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>

    <template #cell(description)="{ item }">
      <span data-testid="pipeline-schedule-description">
        {{ item.description }}
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
