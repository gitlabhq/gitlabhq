import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { __, n__ } from '~/locale';

export function returnedToYouBadge({ mergeRequest }) {
  const reviewersRequestedChanges = mergeRequest.reviewers.nodes.filter(
    (r) => r.mergeRequestInteraction.reviewState === 'REQUESTED_CHANGES',
  );
  const reviewersReviewed = mergeRequest.reviewers.nodes.filter(
    (r) => r.mergeRequestInteraction.reviewState === 'REVIEWED',
  );

  if (reviewersRequestedChanges.length) {
    return { icon: 'status-alert', text: __('Changes requested'), iconOpticallyAligned: true };
  }

  if (reviewersReviewed.length) {
    return { icon: 'comment-lines', text: __('Reviewer commented') };
  }

  return null;
}

export function reviewsRequestedBadge({ currentUserAsReviewer }) {
  if (currentUserAsReviewer?.mergeRequestInteraction.reviewState === 'REVIEW_STARTED') {
    return { icon: 'comment-dots', text: __('Review started') };
  }

  if (
    ['UNREVIEWED', 'UNAPPROVED'].includes(
      currentUserAsReviewer?.mergeRequestInteraction.reviewState,
    )
  ) {
    return { icon: 'review-list', text: __('Requested') };
  }

  return null;
}

export function assignedToYouBadge({ mergeRequest }) {
  if (mergeRequest.draft) {
    return { icon: 'merge-request', text: __('Draft') };
  }

  if (mergeRequest.reviewers?.nodes.length === 0) {
    return { icon: 'user', text: __('Reviewers needed') };
  }

  return null;
}

export function waitingForAssigneeBadge({ currentUserAsReviewer }) {
  if (currentUserAsReviewer?.mergeRequestInteraction.reviewState === 'REQUESTED_CHANGES') {
    return {
      icon: 'status-alert',
      text: __('You requested changes'),
      variant: 'muted',
      iconOpticallyAligned: true,
    };
  }

  if (currentUserAsReviewer?.mergeRequestInteraction.reviewState === 'REVIEWED') {
    return { icon: 'comment-lines', text: __('You commented'), variant: 'muted' };
  }

  return null;
}

export function approvalBadge({ mergeRequest, currentUserId }) {
  const reviewersNotApproved = mergeRequest.reviewers.nodes.filter(
    (r) => r.mergeRequestInteraction.reviewState !== 'APPROVED',
  );

  if (
    mergeRequest.approvalsLeft > 0 ||
    (mergeRequest.approvalsRequired === 0 && reviewersNotApproved.length > 0)
  ) {
    return {
      icon: 'hourglass',
      text: n__(
        '%d approval required',
        '%d approvals required',
        mergeRequest.approvalsLeft || reviewersNotApproved.length,
      ),
      variant: 'muted',
    };
  }

  if (
    mergeRequest.approvedBy?.nodes.find((u) => u.id === currentUserId) ||
    mergeRequest.approvalsLeft === 0
  ) {
    return {
      icon: 'check-circle-filled',
      text: __('Approved'),
      variant: 'muted',
      iconOpticallyAligned: true,
    };
  }

  return { icon: 'hourglass', text: __('Waiting for approval'), variant: 'muted' };
}

export function mergedBadge({ mergeRequest }) {
  return {
    icon: 'check-circle-filled',
    text: __('Merged'),
    variant: 'info',
    iconOpticallyAligned: true,
    title: localeDateFormat.asDateTimeFull.format(newDate(mergeRequest.mergedAt)),
  };
}

export const BADGE_METHODS = {
  returned_to_you: [returnedToYouBadge],
  reviews_requested: [reviewsRequestedBadge],
  assigned_to_you: [assignedToYouBadge],
  waiting_for_assignee: [waitingForAssigneeBadge],
  waiting_for_approvals: [approvalBadge],
  approved_by_you: [approvalBadge],
  approved_by_others: [approvalBadge],
  merged_recently: [mergedBadge],
  merged_recently_reviews: [mergedBadge],
  merged_recently_assigned: [mergedBadge],
  reviews: [reviewsRequestedBadge, approvalBadge],
  reviews_inactive: [waitingForAssigneeBadge, approvalBadge],
  assigned: [returnedToYouBadge, assignedToYouBadge, approvalBadge],
  assigned_inactive: [returnedToYouBadge, approvalBadge],
};
