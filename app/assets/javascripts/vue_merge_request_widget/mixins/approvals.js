import { createAlert } from '~/alert';
import approvedByQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import { FETCH_ERROR } from '../components/approvals/messages';

export default {
  apollo: {
    approvals: {
      query: approvedByQuery,
      variables() {
        return {
          projectPath: this.mr.targetProjectFullPath,
          iid: `${this.mr.iid}`,
        };
      },
      update: (data) => data.project.mergeRequest,
      result({ data }) {
        const { mergeRequest } = data.project;

        this.disableCommittersApproval = data.project.mergeRequestsDisableCommittersApproval;

        this.mr.setApprovals(mergeRequest);
      },
      error() {
        createAlert({
          message: FETCH_ERROR,
        });
      },
    },
  },
  data() {
    return {
      alerts: [],
      approvals: {},
      disableCommittersApproval: false,
    };
  },
  methods: {
    clearError() {
      this.$emit('clearError');
      this.hasApprovalAuthError = false;
      this.alerts.forEach((alert) => alert.dismiss());
      this.alerts = [];
    },
    refreshApprovals() {
      return this.service.fetchApprovals().then((data) => {
        this.mr.setApprovals(data);
      });
    },
  },
};
