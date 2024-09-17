<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __ } from '~/locale';
import FailedJobsList from './failed_jobs_list.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    FailedJobsList,
    CrudComponent,
  },
  inject: ['fullPath'],
  props: {
    failedJobsCount: {
      required: true,
      type: Number,
    },
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
  data() {
    return {
      currentFailedJobsCount: this.failedJobsCount,
      isActive: false,
      isExpanded: false,
    };
  },
  computed: {
    bodyClasses() {
      return this.isExpanded ? '' : 'gl-hidden';
    },
    iconName() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    isMaximumJobLimitReached() {
      return this.currentFailedJobsCount > 100;
    },
  },
  watch: {
    failedJobsCount(val) {
      this.currentFailedJobsCount = val;
    },
  },
  methods: {
    setFailedJobsCount(count) {
      this.currentFailedJobsCount = count;
    },
    toggleWidget() {
      this.isExpanded = !this.isExpanded;
    },
  },
  i18n: {
    failedJobsLabel: __('Failed jobs'),
  },
  ariaControlsId: 'pipeline-failed-jobs-widget',
};
</script>
<template>
  <crud-component
    :id="$options.ariaControlsId"
    class="expandable-card"
    :class="{ 'is-collapsed gl-border-white hover:gl-border-gray-100': !isExpanded }"
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
        <span class="gl-font-bold gl-text-secondary">
          {{ $options.i18n.failedJobsLabel }}
        </span>
        <span> ({{ currentFailedJobsCount }}) </span>
      </gl-button>
    </template>
    <failed-jobs-list
      v-if="isExpanded"
      :failed-jobs-count="failedJobsCount"
      :is-maximum-job-limit-reached="isMaximumJobLimitReached"
      :is-pipeline-active="isPipelineActive"
      :pipeline-iid="pipelineIid"
      :pipeline-path="pipelinePath"
      :project-path="projectPath"
      @failed-jobs-count="setFailedJobsCount"
    />
  </crud-component>
</template>
