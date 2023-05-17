import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';

export const createCanApproveResponse = () => {
  const response = JSON.parse(JSON.stringify(approvedByCurrentUser));
  response.data.project.mergeRequest.userPermissions.canApprove = true;
  response.data.project.mergeRequest.approved = false;
  response.data.project.mergeRequest.approvedBy.nodes = [];

  return response;
};
