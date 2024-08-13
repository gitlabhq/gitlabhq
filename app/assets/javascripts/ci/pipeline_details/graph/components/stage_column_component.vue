<script>
import { escape, isEmpty } from 'lodash';
import ActionComponent from '~/ci/common/private/job_action_component.vue';
import { reportToSentry } from '~/ci/utils';
import { __, s__, sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { sanitize } from '~/lib/dompurify';
import RootGraphLayout from './root_graph_layout.vue';
import JobGroupDropdown from './job_group_dropdown.vue';
import JobItem from './job_item.vue';

export default {
  components: {
    ActionComponent,
    JobGroupDropdown,
    JobItem,
    RootGraphLayout,
  },
  i18n: {
    confirmationModal: {
      title: s__('PipelineGraph|Are you sure you want to run %{stageName}?'),
      actionCancel: { text: __('Cancel') },
      actionPrimary: { text: __('Confirm') },
    },
  },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: true,
    },
    action: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    highlightedJobs: {
      type: Array,
      required: false,
      default: () => [],
    },
    isStageView: {
      type: Boolean,
      required: false,
      default: false,
    },
    jobHovered: {
      type: String,
      required: false,
      default: '',
    },
    pipelineExpanded: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    skipRetryModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceJobHovered: {
      type: String,
      required: false,
      default: '',
    },
    userPermissions: {
      type: Object,
      required: true,
    },
  },
  jobClasses: [
    'gl-p-3',
    'gl-border-0',
    'gl-rounded-base',
    'hover:gl-bg-strong',
    'focus:gl-bg-strong',
    'gl-hover-text-gray-900',
    'gl-focus-text-gray-900',
  ],
  data() {
    return {
      showConfirmationModal: false,
      shouldTriggerActionClick: false,
    };
  },
  computed: {
    canUpdatePipeline() {
      return this.userPermissions.updatePipeline;
    },
    columnSpacingClass() {
      return this.isStageView ? 'is-stage-view gl-m-5' : 'gl-my-5 gl-mx-7';
    },
    hasAction() {
      return !isEmpty(this.action);
    },
    showStageName() {
      return !this.isStageView;
    },
    withConfirmationModal() {
      return this.action.confirmationMessage !== null;
    },
    confirmationTitle() {
      return sprintf(this.$options.i18n.confirmationModal.title, {
        stageName: this.name,
      });
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('stage_column_component', `error: ${err}, info: ${info}`);
  },
  mounted() {
    this.$emit('updateMeasurements');
  },
  methods: {
    getGroupId(group) {
      return group.name;
    },
    groupId(group) {
      return `ci-badge-${escape(group.name)}`;
    },
    isFadedOut(jobName) {
      return this.highlightedJobs.length > 1 && !this.highlightedJobs.includes(jobName);
    },
    isParallel(group) {
      return group.size > 1 && group.jobs.length > 1;
    },
    singleJobExists(group) {
      const firstJobDefined = Boolean(group.jobs?.[0]);

      if (!firstJobDefined) {
        reportToSentry('stage_column_component', 'undefined_job_hunt');
      }

      return group.size === 1 && firstJobDefined;
    },
    showActionConfirmationModal() {
      this.showConfirmationModal = true;
    },
    executePendingAction() {
      this.shouldTriggerActionClick = true;
    },
    async actionClicked() {
      if (this.action.confirmationMessage !== null) {
        const confirmed = await confirmAction(null, {
          title: sprintf(this.$options.i18n.confirmationModal.title, {
            stageName: sanitize(this.name),
          }),
          modalHtmlMessage: `
            <p>${sprintf(__('Custom confirmation message: %{message}'), {
              message: sanitize(this.action.confirmationMessage),
            })}</p>
            <p>${s__('PipelineGraph|Do you want to continue?')}</p>
          `,
          primaryBtnText: sprintf(__('Yes, run all manual')),
        });

        if (!confirmed) {
          return;
        }
      }
      this.executePendingAction();
    },
  },
};
</script>
<template>
  <root-graph-layout
    :class="columnSpacingClass"
    class="stage-column gl-relative gl-flex-basis-full"
    data-testid="stage-column"
  >
    <template #stages>
      <div
        data-testid="stage-column-title"
        class="stage-column-title gl-flex gl-justify-between gl-relative gl-font-bold gl-pipeline-job-width gl-text-truncate gl-leading-36 gl-pl-4 -gl-mb-2"
      >
        <span :title="name" class="gl-text-truncate gl-pr-3 gl-w-17/20">
          {{ name }}
        </span>
        <action-component
          v-if="hasAction && canUpdatePipeline"
          :should-trigger-click="shouldTriggerActionClick"
          :action-icon="action.icon"
          :tooltip-text="action.title"
          :link="action.path"
          :with-confirmation-modal="withConfirmationModal"
          class="js-stage-action"
          @click.native="actionClicked"
          @pipelineActionRequestComplete="$emit('refreshPipelineGraph')"
        />
      </div>
    </template>
    <template #jobs>
      <div
        v-for="group in groups"
        :id="groupId(group)"
        :key="getGroupId(group)"
        data-testid="stage-column-group"
        class="gl-relative gl-whitespace-normal gl-pipeline-job-width gl-mb-2"
        @mouseenter="$emit('jobHover', group.name)"
        @mouseleave="$emit('jobHover', '')"
      >
        <job-item
          v-if="singleJobExists(group)"
          :job="group.jobs[0]"
          :job-hovered="jobHovered"
          :skip-retry-modal="skipRetryModal"
          :source-job-hovered="sourceJobHovered"
          :pipeline-expanded="pipelineExpanded"
          :pipeline-id="pipelineId"
          :stage-name="showStageName ? group.stageName : ''"
          :css-class-job-name="$options.jobClasses"
          :class="[{ 'gl-opacity-3': isFadedOut(group.name) }, 'gl-duration-slow gl-ease-ease']"
          @pipelineActionRequestComplete="$emit('refreshPipelineGraph')"
          @setSkipRetryModal="$emit('setSkipRetryModal')"
        />
        <div v-else-if="isParallel(group)" :class="{ 'gl-opacity-3': isFadedOut(group.name) }">
          <job-group-dropdown
            :group="group"
            :stage-name="showStageName ? group.stageName : ''"
            :pipeline-id="pipelineId"
            :css-class-job-name="$options.jobClasses"
          />
        </div>
      </div>
    </template>
  </root-graph-layout>
</template>
