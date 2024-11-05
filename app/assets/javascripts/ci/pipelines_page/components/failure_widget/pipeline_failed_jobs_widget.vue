<script>
import { GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __ } from '~/locale';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import { graphqlEtagPipelinePath } from '~/ci/pipeline_details/utils';
import getPipelineFailedJobsCount from '../../graphql/queries/get_pipeline_failed_jobs_count.query.graphql';
import FailedJobsList from './failed_jobs_list.vue';
import { POLL_INTERVAL } from './constants';

export default {
  fetchError: __('An error occured fetching failed jobs count'),
  components: {
    GlBadge,
    GlButton,
    GlIcon,
    FailedJobsList,
    CrudComponent,
  },
  inject: ['fullPath', 'graphqlPath'],
  props: {
    isPipelineActive: {
      required: true,
      type: Boolean,
    },
    pipelineIid: {
      required: true,
      type: Number,
    },
    pipelinePath: {
      required: true,
      type: String,
    },
    projectPath: {
      required: true,
      type: String,
    },
  },
  apollo: {
    failedJobsCount: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineFailedJobsCount,
      // Only poll if the pipeline is active
      pollInterval() {
        return this.isPipelineActive ? POLL_INTERVAL : 0;
      },
      variables() {
        return {
          fullPath: this.projectPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update({ project }) {
        return project?.pipeline?.jobs?.count || 0;
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  data() {
    return {
      failedJobsCount: 0,
      isExpanded: false,
    };
  },
  computed: {
    graphqlResourceEtag() {
      return graphqlEtagPipelinePath(this.graphqlPath, this.pipelineIid);
    },
    bodyClasses() {
      return this.isExpanded ? '' : 'gl-hidden';
    },
    failedJobsCountBadge() {
      return `${this.isMaximumJobLimitReached ? '100+' : this.failedJobsCount}`;
    },
    iconName() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    isMaximumJobLimitReached() {
      return this.failedJobsCount > 100;
    },
  },
  methods: {
    toggleWidget() {
      this.isExpanded = !this.isExpanded;
    },
    async refetchCount() {
      try {
        await this.$apollo.queries.failedJobsCount.refetch();
      } catch {
        createAlert({ message: this.$options.i18n.fetchError });
      }
    },
  },
  ariaControlsId: 'pipeline-failed-jobs-widget',
};
</script>
<template>
  <crud-component
    :id="$options.ariaControlsId"
    class="expandable-card"
    :class="{ 'is-collapsed gl-border-transparent hover:gl-border-default': !isExpanded }"
    data-testid="failed-jobs-card"
    @click="toggleWidget"
  >
    <template #title>
      <gl-button
        variant="link"
        class="!gl-text-subtle"
        :aria-expanded="isExpanded.toString()"
        :aria-controls="$options.ariaControlsId"
        @click="toggleWidget"
      >
        <gl-icon :name="iconName" class="gl-mr-2" />
        <span class="gl-font-bold gl-text-subtle">
          {{ __('Failed jobs') }}
        </span>
      </gl-button>
    </template>
    <template #count>
      <gl-badge>
        {{ failedJobsCountBadge }}
      </gl-badge>
    </template>
    <failed-jobs-list
      v-if="isExpanded"
      :is-maximum-job-limit-reached="isMaximumJobLimitReached"
      :pipeline-iid="pipelineIid"
      :pipeline-path="pipelinePath"
      :project-path="projectPath"
      @job-retried="refetchCount"
    />
  </crud-component>
</template>
