import {
  returnedToYouBadge,
  reviewsRequestedBadge,
  assignedToYouBadge,
  waitingForAssigneeBadge,
  approvalBadge,
  mergedBadge,
} from '~/merge_request_dashboard/utils/status_badge';

describe('returnedToYouBadge', () => {
  it.each`
    reviewState            | data
    ${'REQUESTED_CHANGES'} | ${{ icon: 'status-alert', text: 'Changes requested', iconOpticallyAligned: true }}
    ${'REVIEWED'}          | ${{ icon: 'comment-lines', text: 'Reviewer commented' }}
  `('returns $data when reviewState is $reviewState', ({ reviewState, data }) => {
    expect(
      returnedToYouBadge({
        mergeRequest: {
          reviewers: {
            nodes: [
              {
                mergeRequestInteraction: {
                  reviewState,
                },
              },
            ],
          },
        },
      }),
    ).toEqual(data);
  });
});

describe('reviewsRequestedBadge', () => {
  it.each`
    reviewState         | data
    ${'REVIEW_STARTED'} | ${{ icon: 'comment-dots', text: 'Review started' }}
    ${'UNREVIEWED'}     | ${{ icon: 'review-list', text: 'Requested' }}
  `(
    'returns $data when currentUserAsReviewer reviewState is $reviewState',
    ({ reviewState, data }) => {
      expect(
        reviewsRequestedBadge({
          currentUserAsReviewer: {
            mergeRequestInteraction: {
              reviewState,
            },
          },
        }),
      ).toEqual(data);
    },
  );
});

describe('assignedToYouBadge', () => {
  it.each`
    draft    | data
    ${true}  | ${{ icon: 'merge-request', text: 'Draft' }}
    ${false} | ${{ icon: 'user', text: 'Reviewers needed' }}
  `('returns $data when draft $draft', ({ draft, data }) => {
    expect(
      assignedToYouBadge({
        mergeRequest: {
          draft,
        },
      }),
    ).toEqual(data);
  });
});

describe('waitingForAssigneeBadge', () => {
  it.each`
    reviewState            | data
    ${'REQUESTED_CHANGES'} | ${{ icon: 'status-alert', text: 'You requested changes', iconOpticallyAligned: true, variant: 'muted' }}
    ${'REVIEWED'}          | ${{ icon: 'comment-lines', text: 'You commented', variant: 'muted' }}
  `('returns $data when reviewState is $reviewState', ({ reviewState, data }) => {
    expect(
      waitingForAssigneeBadge({
        currentUserAsReviewer: {
          mergeRequestInteraction: {
            reviewState,
          },
        },
      }),
    ).toEqual(data);
  });
});

describe('approvalBadge', () => {
  describe('when approvalsLeft is more than 0', () => {
    it.each`
      approvalsLeft | data
      ${1}          | ${{ icon: 'hourglass', text: '1 approval required', variant: 'muted' }}
      ${2}          | ${{ icon: 'hourglass', text: '2 approvals required', variant: 'muted' }}
    `('returns $data when approvalsLeft $approvalsLeft', ({ approvalsLeft, data }) => {
      expect(
        approvalBadge({
          mergeRequest: {
            approvalsLeft,
            reviewers: { nodes: [{ mergeRequestInteraction: { reviewState: 'REVIEWED' } }] },
          },
        }),
      ).toEqual(data);
    });
  });

  describe('with approvalsRequired', () => {
    it.each`
      approvalsRequired | approvalsLeft | reviewState   | data
      ${0}              | ${0}          | ${'APPROVED'} | ${{ icon: 'check-circle-filled', text: 'Approved' }}
      ${1}              | ${0}          | ${'APPROVED'} | ${{ icon: 'check-circle-filled', text: 'Approved' }}
      ${0}              | ${1}          | ${'APPROVED'} | ${{ icon: 'hourglass', text: '1 approval required' }}
      ${0}              | ${2}          | ${'APPROVED'} | ${{ icon: 'hourglass', text: '2 approvals required' }}
      ${0}              | ${0}          | ${'REVIEWED'} | ${{ icon: 'hourglass', text: '1 approval required' }}
    `(
      'returns $data when approvalsRequired $approvalsRequired, reviewState is $reviewState, approvalsLeft is $approvalsLeft',
      ({ approvalsRequired, approvalsLeft, reviewState, data }) => {
        expect(
          approvalBadge({
            mergeRequest: {
              approvalsRequired,
              approvalsLeft,
              reviewers: { nodes: [{ mergeRequestInteraction: { reviewState } }] },
            },
          }),
        ).toEqual(expect.objectContaining(data));
      },
    );
  });

  describe('when using approved by current user', () => {
    it.each`
      approved | data
      ${true}  | ${{ icon: 'check-circle-filled', text: 'Approved', variant: 'muted', iconOpticallyAligned: true }}
      ${false} | ${{ icon: 'hourglass', text: 'Waiting for approval', variant: 'muted' }}
    `('returns $data when approved is $approved', ({ approved, data }) => {
      expect(
        approvalBadge({
          currentUserId: 1,
          mergeRequest: {
            reviewers: { nodes: [] },
            approvedBy: { nodes: [{ id: approved ? 1 : 2 }] },
          },
        }),
      ).toEqual(data);
    });
  });
});

describe('mergedBadge', () => {
  it('returns badge data', () => {
    expect(mergedBadge({ mergeRequest: { mergedAt: '01-01-2025' } })).toEqual(
      expect.objectContaining({
        icon: 'check-circle-filled',
        text: 'Merged',
        variant: 'info',
        iconOpticallyAligned: true,
      }),
    );
  });
});
