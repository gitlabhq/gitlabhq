import { n__, s__, sprintf } from '~/locale';
import Flash from '~/flash';
import MRWidgetAuthor from '~/vue_merge_request_widget/components/mr_widget_author.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

export default {
  name: 'approvals-body',
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
    },
    approvalsLeft: {
      type: Number,
      required: false,
    },
    userCanApprove: {
      type: Boolean,
      required: false,
    },
    userHasApproved: {
      type: Boolean,
      required: false,
    },
    suggestedApprovers: {
      type: Array,
      required: false,
    },
  },
  components: {
    'mr-widget-author': MRWidgetAuthor,
  },
  data() {
    return {
      approving: false,
    };
  },
  computed: {
    approvalsRequiredStringified() {
      if (this.approvalsLeft === 0) {
        return s__('mrWidget|Approved');
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
    showApproveButton() {
      return this.userCanApprove && !this.userHasApproved && this.mr.isOpen;
    },
    showSuggestedApprovers() {
      return this.suggestedApprovers && this.suggestedApprovers.length;
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
          Flash(s__('mrWidget|An error occured while submitting your approval.'));
        });
    },
  },
  template: `
    <div class="approvals-body space-children">
      <span v-if="showApproveButton" class="approvals-approve-button-wrap">
        <button
          :disabled="approving"
          @click="approveMergeRequest"
          class="btn btn-primary btn-sm approve-btn"
          :class="approveButtonClass">
          <i
            v-if="approving"
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
          {{approveButtonText}}
        </button>
      </span>
      <span class="approvals-required-text bold">
        {{approvalsRequiredStringified}}
        <span v-if="showSuggestedApprovers">
          <mr-widget-author
            v-for="approver in suggestedApprovers"
            :key="approver.username"
            :author="approver"
            :show-author-name="false"
            :show-author-tooltip="true" />
        </span>
      </span>
    </div>
  `,
};
