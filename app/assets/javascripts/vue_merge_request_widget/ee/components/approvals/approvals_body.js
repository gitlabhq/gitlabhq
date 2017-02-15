/* global Flash */
import MRWidgetAuthor from '../../../components/mr_widget_author';
import eventHub from '../../../event_hub';

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
      const baseString = `${this.approvalsLeft} more approval`;
      return this.approvalsLeft === 1 ? baseString : `${baseString}s`;
    },
    showApproveButton() {
      return this.userCanApprove && !this.userHasApproved;
    },
    showSuggestedApprovers() {
      return this.suggestedApprovers && this.suggestedApprovers.length;
    },
  },
  methods: {
    approveMergeRequest() {
      this.approving = true;
      this.service.approveMergeRequest()
        .then((data) => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.approving = false;
        })
        .catch(() => {
          this.approving = false;
          new Flash('An error occured while submitting your approval.'); // eslint-disable-line
        });
    },
  },
  template: `
    <div class="approvals-body">
      <span v-if="showApproveButton" class="approvals-approve-button-wrap">
        <button
          :disabled="approving"
          @click="approveMergeRequest"
          class="btn btn-primary btn-small approve-btn">
          <i
            v-if="approving"
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
          Approve
        </button>
      </span>
      <span class="approvals-required-text bold">
        Requires {{approvalsRequiredStringified}}
        <span v-if="showSuggestedApprovers">
          <span class="dash">&mdash;</span>
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
