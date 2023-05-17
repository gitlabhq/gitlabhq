<script>
import { GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import ProjectCell from '~/pages/admin/jobs/components/table/cell/project_cell.vue';
import RunnerCell from '~/pages/admin/jobs/components/table/cells/runner_cell.vue';
import ActionsCell from './cells/actions_cell.vue';
import DurationCell from './cells/duration_cell.vue';
import JobCell from './cells/job_cell.vue';
import PipelineCell from './cells/pipeline_cell.vue';
import { DEFAULT_FIELDS } from './constants';

export default {
  i18n: {
    emptyText: s__('Jobs|No jobs to show'),
  },
  components: {
    ActionsCell,
    CiBadgeLink,
    DurationCell,
    GlTable,
    JobCell,
    PipelineCell,
    ProjectCell,
    RunnerCell,
  },
  props: {
    jobs: {
      type: Array,
      required: true,
    },
    tableFields: {
      type: Array,
      required: false,
      default: () => DEFAULT_FIELDS,
    },
    admin: {
      type: Boolean,
      required: false,
      default: false,
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
      <ci-badge-link :status="item.detailedStatus" />
    </template>

    <template #cell(job)="{ item }">
      <job-cell :job="item" />
    </template>

    <template #cell(pipeline)="{ item }">
      <pipeline-cell :job="item" />
    </template>

    <template v-if="admin" #cell(project)="{ item }">
      <project-cell :job="item" />
    </template>

    <template v-if="admin" #cell(runner)="{ item }">
      <runner-cell :job="item" />
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
      <actions-cell class="gl-float-right" :job="item" />
    </template>
  </gl-table>
</template>
