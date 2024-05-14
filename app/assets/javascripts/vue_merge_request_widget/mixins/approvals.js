import mergeRequestApprovalStateUpdated from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.subscription.graphql';
import approvedByQuery from 'ee_else_ce/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';

import { createAlert } from '~/alert';

import { convertToGraphQLId } from '../../graphql_shared/utils';
import { TYPENAME_MERGE_REQUEST } from '../../graphql_shared/constants';

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
      update: (data) => data.project?.mergeRequest,
      result({ data }) {
        // This case can occur when backend returns an empty project due to expired session.
        // See https://gitlab.com/gitlab-org/gitlab/-/issues/413627 for more information.
        if (!data.project) {
          // Needed to suppress several errors.
          this.mr.setApprovals({});
          return;
        }

        const { mergeRequest } = data.project;

        this.disableCommittersApproval = data.project.mergeRequestsDisableCommittersApproval;

        this.mr.setApprovals(mergeRequest);
      },
      error() {
        createAlert({
          message: FETCH_ERROR,
        });
      },
      subscribeToMore: {
        document: mergeRequestApprovalStateUpdated,
        variables() {
          return {
            issuableId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.mr.id),
          };
        },
        skip() {
          return !this.mr?.id;
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { mergeRequestApprovalStateUpdated: queryResult },
            },
          },
        ) {
          if (queryResult) {
            this.mr.setApprovals(queryResult);
          }
        },
      },
    },
  },
  data() {
    return {
      alerts: [],
      approvals: null,
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
