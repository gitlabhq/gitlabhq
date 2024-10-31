import reviewerQuery from './queries/reviewer.query.graphql';
import reviewerCountQuery from './queries/reviewer_count.query.graphql';
import assigneeQuery from './queries/assignee.query.graphql';
import assigneeCountQuery from './queries/assignee_count.query.graphql';
import assigneeOrReviewerQuery from './queries/assignee_or_reviewer.query.graphql';
import assigneeOrReviewerCountQuery from './queries/assignee_or_reviewer_count.query.graphql';

export const QUERIES = {
  reviewRequestedMergeRequests: { dataQuery: reviewerQuery, countQuery: reviewerCountQuery },
  assignedMergeRequests: { dataQuery: assigneeQuery, countQuery: assigneeCountQuery },
  assigneeOrReviewerMergeRequests: {
    dataQuery: assigneeOrReviewerQuery,
    countQuery: assigneeOrReviewerCountQuery,
  },
};
