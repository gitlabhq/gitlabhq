<script>
import { GlButton, GlCollapse, GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import FailedJobsList from './failed_jobs_list.vue';

export default {
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
    FailedJobsList,
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
      return this.isExpanded ? '' : 'gl-display-none';
    },
    failedJobsCountText() {
      return sprintf(this.$options.i18n.showFailedJobs, { count: this.currentFailedJobsCount });
    },
    iconName() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    popoverId() {
      return `popover-${this.pipelineIid}`;
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
    additionalInfoPopover: s__(
      'Pipelines|You will see a maximum of 100 jobs in this list. To view all failed jobs, %{linkStart}go to the details page%{linkEnd} of this pipeline.',
    ),
    additionalInfoTitle: __('Limitation on this view'),
    showFailedJobs: __('Show failed jobs (%{count})'),
  },
};
</script>
<template>
  <div class="gl-border-none!">
    <gl-button variant="link" @click="toggleWidget">
      <gl-icon :name="iconName" />
      {{ failedJobsCountText }}
      <gl-icon :id="popoverId" name="information-o" />
      <gl-popover :target="popoverId" placement="top">
        <template #title> {{ $options.i18n.additionalInfoTitle }} </template>
        <slot>
          <gl-sprintf :message="$options.i18n.additionalInfoPopover">
            <template #link="{ content }">
              <gl-link class="gl-font-sm" :href="pipelinePath"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </slot>
      </gl-popover>
    </gl-button>
    <gl-collapse
      v-model="isExpanded"
      class="gl-bg-gray-10 gl-border-1 gl-border-t gl-border-color-gray-100 gl-mt-4 gl-pt-3"
    >
      <failed-jobs-list
        v-if="isExpanded"
        :is-pipeline-active="isPipelineActive"
        :pipeline-iid="pipelineIid"
        @failed-jobs-count="setFailedJobsCount"
      />
    </gl-collapse>
  </div>
</template>
