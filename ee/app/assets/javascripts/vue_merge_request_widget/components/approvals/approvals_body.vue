<script>
import { n__, s__, sprintf } from '~/locale';
import Flash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';
import MrWidgetAuthor from '~/vue_merge_request_widget/components/mr_widget_author.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import eventHub from '~/vue_merge_request_widget/event_hub';

export default {
  name: 'ApprovalsBody',
  components: {
    MrWidgetAuthor,
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
    approvedBy: {
      type: Array,
      required: false,
      default: () => [],
    },
    approvalsOptional: {
      type: Boolean,
      required: false,
      default: false,
    },
    approvalsLeft: {
      type: Number,
      required: false,
      default: 0,
    },
    userCanApprove: {
      type: Boolean,
      required: false,
      default: false,
    },
    userHasApproved: {
      type: Boolean,
      required: false,
      default: false,
    },
    suggestedApprovers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      approving: false,
    };
  },
  computed: {
    approvalsRequiredStringified() {
      if (this.approvalsOptional) {
        if (this.userCanApprove) {
          return s__('mrWidget|No Approval required; you can still approve');
        }

        return s__('mrWidget|No Approval required');
      }

      if (this.approvalsLeft === 0) {
        return this.userCanApprove ?
          s__('mrWidget|Merge request approved; you can approve additionally') :
          s__('mrWidget|Merge request approved');
      }

      if (this.suggestedApprovers.length >= 1) {
        return sprintf(
          n__(
            'mrWidget|Requires 1 more approval by',
            'mrWidget|Requires %d more approvals by',
            this.approvalsLeft,
          ),
        );
      }

      return sprintf(
        n__(
          'mrWidget|Requires 1 more approval',
          'mrWidget|Requires %d more approvals',
          this.approvalsLeft,
        ),
      );
    },
    approveButtonText() {
      let approveButtonText = s__('mrWidget|Approve');
      if (this.approvalsLeft <= 0) {
        approveButtonText = s__('mrWidget|Add approval');
      }
      return approveButtonText;
    },
    approveButtonClass() {
      return {
        'btn-inverted': this.showApproveButton && this.approvalsLeft <= 0,
      };
    },
    showApprovalDocLink() {
      return this.approvalsOptional && this.showApproveButton;
    },
    showApproveButton() {
      return this.userCanApprove && !this.userHasApproved && this.mr.isOpen;
    },
    showSuggestedApprovers() {
      return this.approvalsLeft > 0 && this.suggestedApprovers && this.suggestedApprovers.length;
    },
  },
  methods: {
    approveMergeRequest() {
      this.approving = true;
      this.service
        .approveMergeRequest()
        .then(data => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.approving = false;
        })
        .catch(() => {
          this.approving = false;
          Flash(s__('mrWidget|An error occurred while submitting your approval.'));
        });
    },
  },
};
</script>

<template>
  <div class="approvals-body space-children">
    <span
      v-if="showApproveButton"
      class="approvals-approve-button-wrap"
    >
      <button
        :disabled="approving"
        :class="approveButtonClass"
        class="btn btn-primary btn-sm approve-btn"
        @click="approveMergeRequest"
      >
        <i
          v-if="approving"
          class="fa fa-spinner fa-spin"
          aria-hidden="true"
        ></i>
        {{ approveButtonText }}
      </button>
    </span>
    <span
      :class="approvalsOptional ? 'text-muted' : 'bold'"
      class="approvals-required-text"
    >
      {{ approvalsRequiredStringified }}
      <a
        v-tooltip
        v-if="showApprovalDocLink"
        :href="mr.approvalsHelpPath"
        :title="__('About this feature')"
        data-placement="bottom"
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-container="body"
      >
        <icon
          name="question-o"
        />
      </a>
      <span v-if="showSuggestedApprovers">
        <mr-widget-author
          v-for="approver in suggestedApprovers"
          :key="approver.username"
          :author="approver"
          :show-author-name="false"
          :show-author-tooltip="true"
        />
      </span>
    </span>
  </div>
</template>
