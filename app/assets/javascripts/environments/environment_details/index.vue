<script>
import {
  GlTableLite,
  GlAvatarLink,
  GlAvatar,
  GlLink,
  GlTooltipDirective,
  GlTruncate,
  GlBadge,
  GlLoadingIcon,
} from '@gitlab/ui';
import Commit from '~/vue_shared/components/commit.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import environmentDetailsQuery from '../graphql/queries/environment_details.query.graphql';
import { convertToDeploymentTableRow } from '../helpers/deployment_data_transformation_helper';
import DeploymentStatusBadge from '../components/deployment_status_badge.vue';
import { ENVIRONMENT_DETAILS_PAGE_SIZE, ENVIRONMENT_DETAILS_TABLE_FIELDS } from './constants';

export default {
  components: {
    GlLoadingIcon,
    GlBadge,
    DeploymentStatusBadge,
    TimeAgoTooltip,
    GlTableLite,
    GlAvatarLink,
    GlAvatar,
    GlLink,
    GlTruncate,
    Commit,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query: environmentDetailsQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.environmentName,
          pageSize: ENVIRONMENT_DETAILS_PAGE_SIZE,
        };
      },
    },
  },
  data() {
    return {
      project: {
        loading: true,
      },
      loading: 0,
      tableFields: ENVIRONMENT_DETAILS_TABLE_FIELDS,
    };
  },
  computed: {
    deployments() {
      return this.project.environment?.deployments.nodes.map(convertToDeploymentTableRow) || [];
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="mt-3" />
    <gl-table-lite v-else :items="deployments" :fields="tableFields" fixed stacked="lg">
      <template #table-colgroup="{ fields }">
        <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
      </template>
      <template #cell(status)="{ item }">
        <div>
          <deployment-status-badge :status="item.status" />
        </div>
      </template>
      <template #cell(id)="{ item }">
        <strong>{{ item.id }}</strong>
      </template>
      <template #cell(triggerer)="{ item }">
        <gl-avatar-link :href="item.triggerer.webUrl">
          <gl-avatar
            v-gl-tooltip
            :title="item.triggerer.name"
            :src="item.triggerer.avatarUrl"
            :size="24"
          />
        </gl-avatar-link>
      </template>
      <template #cell(commit)="{ item }">
        <commit v-bind="item.commit" />
      </template>
      <template #cell(job)="{ item }">
        <gl-link v-if="item.job" :href="item.job.webPath">
          <gl-truncate :text="item.job.label" />
        </gl-link>
        <gl-badge v-else variant="info">{{ __('API') }}</gl-badge>
      </template>
      <template #cell(created)="{ item }">
        <time-ago-tooltip :time="item.created" />
      </template>
      <template #cell(deployed)="{ item }">
        <time-ago-tooltip :time="item.deployed" />
      </template>
    </gl-table-lite>
  </div>
</template>
