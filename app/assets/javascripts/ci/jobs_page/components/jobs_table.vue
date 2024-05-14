<script>
import { GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectCell from '~/ci/admin/jobs_table/components/cells/project_cell.vue';
import RunnerCell from '~/ci/admin/jobs_table/components/cells/runner_cell.vue';
import { JOBS_DEFAULT_FIELDS } from '../constants';
import ActionsCell from './job_cells/actions_cell.vue';
import StatusCell from './job_cells/status_cell.vue';
import JobCell from './job_cells/job_cell.vue';
import PipelineCell from './job_cells/pipeline_cell.vue';

export default {
  i18n: {
    emptyText: s__('Jobs|No jobs to show'),
  },
  components: {
    ActionsCell,
    StatusCell,
    JobCell,
    PipelineCell,
    ProjectCell,
    RunnerCell,
    GlTable,
  },
  props: {
    jobs: {
      type: Array,
      required: true,
    },
    tableFields: {
      type: Array,
      required: false,
      default: () => JOBS_DEFAULT_FIELDS,
    },
    admin: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    showCoverage(coverage) {
      return coverage || coverage === 0;
    },
    formatCoverage(coverage) {
      return `${coverage}%`;
    },
  },
};
</script>

<template>
  <gl-table
    :items="jobs"
    :fields="tableFields"
    :tbody-tr-attr="{ 'data-testid': 'jobs-table-row' }"
    :empty-text="$options.i18n.emptyText"
    data-testid="jobs-table"
    show-empty
    stacked="lg"
    fixed
  >
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>

    <template #cell(status)="{ item }">
      <status-cell :job="item" />
    </template>

    <template #cell(job)="{ item }">
      <job-cell :job="item" />
    </template>

    <template #cell(pipeline)="{ item }">
      <pipeline-cell :job="item" />
    </template>

    <template #cell(stage)="{ item }">
      <div class="gl-text-truncate">
        <span v-if="item.stage" data-testid="job-stage-name" class="gl-text-secondary">{{
          item.stage.name
        }}</span>
      </div>
    </template>

    <template v-if="admin" #cell(project)="{ item }">
      <project-cell :job="item" />
    </template>

    <template v-if="admin" #cell(runner)="{ item }">
      <runner-cell :job="item" />
    </template>

    <template #cell(coverage)="{ item }">
      <span v-if="showCoverage(item.coverage)" data-testid="job-coverage">
        {{ formatCoverage(item.coverage) }}
      </span>
    </template>

    <template #cell(actions)="{ item }">
      <actions-cell class="gl-float-right" :job="item" />
    </template>
  </gl-table>
</template>
