<script>
import { GlTable } from '@gitlab/ui';
import { DEFAULT_TH_CLASSES } from '~/lib/utils/constants';
import { s__, __ } from '~/locale';
import CiBadge from '~/vue_shared/components/ci_badge_link.vue';
import ActionsCell from './cells/actions_cell.vue';
import DurationCell from './cells/duration_cell.vue';
import JobCell from './cells/job_cell.vue';
import PipelineCell from './cells/pipeline_cell.vue';

const defaultTableClasses = {
  tdClass: 'gl-p-5!',
  thClass: DEFAULT_TH_CLASSES,
};
// eslint-disable-next-line @gitlab/require-i18n-strings
const coverageTdClasses = `${defaultTableClasses.tdClass} gl-display-none! gl-lg-display-table-cell!`;

export default {
  i18n: {
    emptyText: s__('Jobs|No jobs to show'),
  },
  fields: [
    {
      key: 'status',
      label: __('Status'),
      ...defaultTableClasses,
      columnClass: 'gl-w-10p',
    },
    {
      key: 'job',
      label: __('Job'),
      ...defaultTableClasses,
      columnClass: 'gl-w-20p',
    },
    {
      key: 'pipeline',
      label: __('Pipeline'),
      ...defaultTableClasses,
      columnClass: 'gl-w-10p',
    },
    {
      key: 'stage',
      label: __('Stage'),
      ...defaultTableClasses,
      columnClass: 'gl-w-10p',
    },
    {
      key: 'name',
      label: __('Name'),
      ...defaultTableClasses,
      columnClass: 'gl-w-15p',
    },
    {
      key: 'duration',
      label: __('Duration'),
      ...defaultTableClasses,
      columnClass: 'gl-w-15p',
    },
    {
      key: 'coverage',
      label: __('Coverage'),
      tdClass: coverageTdClasses,
      thClass: defaultTableClasses.thClass,
      columnClass: 'gl-w-10p',
    },
    {
      key: 'actions',
      label: '',
      ...defaultTableClasses,
      columnClass: 'gl-w-10p',
    },
  ],
  components: {
    ActionsCell,
    CiBadge,
    DurationCell,
    GlTable,
    JobCell,
    PipelineCell,
  },
  props: {
    jobs: {
      type: Array,
      required: true,
    },
  },
  methods: {
    formatCoverage(coverage) {
      return coverage ? `${coverage}%` : '';
    },
  },
};
</script>

<template>
  <gl-table
    :items="jobs"
    :fields="$options.fields"
    :tbody-tr-attr="{ 'data-testid': 'jobs-table-row' }"
    :empty-text="$options.i18n.emptyText"
    show-empty
    stacked="lg"
    fixed
  >
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>

    <template #cell(status)="{ item }">
      <ci-badge :status="item.detailedStatus" />
    </template>

    <template #cell(job)="{ item }">
      <job-cell :job="item" />
    </template>

    <template #cell(pipeline)="{ item }">
      <pipeline-cell :job="item" />
    </template>

    <template #cell(stage)="{ item }">
      <div class="gl-text-truncate">
        <span data-testid="job-stage-name">{{ item.stage.name }}</span>
      </div>
    </template>

    <template #cell(name)="{ item }">
      <div class="gl-text-truncate">
        <span data-testid="job-name">{{ item.name }}</span>
      </div>
    </template>

    <template #cell(duration)="{ item }">
      <duration-cell :job="item" />
    </template>

    <template #cell(coverage)="{ item }">
      <span v-if="item.coverage" data-testid="job-coverage">{{
        formatCoverage(item.coverage)
      }}</span>
    </template>

    <template #cell(actions)="{ item }">
      <actions-cell :job="item" />
    </template>
  </gl-table>
</template>
