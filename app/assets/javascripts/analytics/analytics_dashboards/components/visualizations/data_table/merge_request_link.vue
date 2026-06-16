<script>
import { GlIcon, GlLink } from '@gitlab/ui';

const PIPELINE_STATUS_SUCCESS = 'SUCCESS';
const PIPELINE_STATUS_PENDING = 'PENDING';
const PIPELINE_STATUS_FAILED = 'FAILED';

export default {
  name: 'MergeRequestLink',
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    webUrl: {
      type: String,
      required: true,
    },
    pipelineStatus: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    labelsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    userNotesCount: {
      type: Number,
      required: false,
      default: 0,
    },
    approvalCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    iidWithPrefix() {
      return `!${this.iid}`;
    },
    pipelineIcon() {
      const { name, label: ariaLabel } = this.pipelineStatus;

      switch (name) {
        case PIPELINE_STATUS_SUCCESS:
          return {
            name: 'status_success',
            variant: 'success',
            ariaLabel,
          };
        case PIPELINE_STATUS_PENDING:
          return {
            name: 'status_pending',
            variant: 'warning',
            ariaLabel,
          };
        case PIPELINE_STATUS_FAILED:
          return {
            name: 'status_failed',
            variant: 'danger',
            ariaLabel,
          };
        default:
          return undefined;
      }
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-grow gl-flex-col">
    <div class="str-truncated-100">
      <gl-link :href="webUrl" target="_blank" class="gl-font-bold gl-text-default">{{
        title
      }}</gl-link>
      <div
        class="gl-mb-0 gl-mt-2 gl-flex gl-items-center gl-justify-end gl-gap-3 @md/panel:gl-justify-start"
      >
        <div data-testid="mr-iid">{{ iidWithPrefix }}</div>
        <div v-if="pipelineIcon">
          <gl-icon v-bind="pipelineIcon" data-testid="pipeline-icon" />
        </div>
        <div :class="{ 'gl-opacity-5': !labelsCount }" data-testid="labels-count">
          <gl-icon name="label" class="gl-mr-1" />
          <span>{{ labelsCount }}</span>
        </div>
        <div :class="{ 'gl-opacity-5': !userNotesCount }" data-testid="user-notes-count">
          <gl-icon name="comments" class="gl-mr-2" />
          <span>{{ userNotesCount }}</span>
        </div>
        <div v-if="approvalCount" class="gl-text-success" data-testid="approval-count">
          <gl-icon name="approval" class="gl-mr-2" variant="success" />
          <span>{{ n__('%d Approval', '%d Approvals', approvalCount) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
