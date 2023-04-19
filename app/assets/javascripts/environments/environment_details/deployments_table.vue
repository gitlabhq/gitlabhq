<script>
import { GlTableLite } from '@gitlab/ui';
import Commit from '~/vue_shared/components/commit.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeploymentStatusLink from './components/deployment_status_link.vue';
import DeploymentJob from './components/deployment_job.vue';
import DeploymentTriggerer from './components/deployment_triggerer.vue';
import DeploymentActions from './components/deployment_actions.vue';
import { ENVIRONMENT_DETAILS_TABLE_FIELDS } from './constants';

export default {
  components: {
    DeploymentTriggerer,
    DeploymentActions,
    DeploymentJob,
    Commit,
    TimeAgoTooltip,
    DeploymentStatusLink,
    GlTableLite,
  },
  props: {
    deployments: {
      type: Array,
      required: true,
    },
  },
  tableFields: ENVIRONMENT_DETAILS_TABLE_FIELDS,
};
</script>
<template>
  <gl-table-lite :items="deployments" :fields="$options.tableFields" fixed stacked="lg">
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>
    <template #cell(status)="{ item }">
      <deployment-status-link :deployment-job="item.job" :status="item.status" />
    </template>
    <template #cell(id)="{ item }">
      <strong>{{ item.id }}</strong>
    </template>
    <template #cell(triggerer)="{ item }">
      <deployment-triggerer :triggerer="item.triggerer" />
    </template>
    <template #cell(commit)="{ item }">
      <commit v-bind="item.commit" />
    </template>
    <template #cell(job)="{ item }">
      <deployment-job :job="item.job" />
    </template>
    <template #cell(created)="{ item }">
      <time-ago-tooltip :time="item.created" />
    </template>
    <template #cell(deployed)="{ item }">
      <time-ago-tooltip :time="item.deployed" />
    </template>
    <template #cell(actions)="{ item }">
      <deployment-actions
        :actions="item.actions"
        :rollback="item.rollback"
        :approval-environment="item.deploymentApproval"
      />
    </template>
  </gl-table-lite>
</template>
