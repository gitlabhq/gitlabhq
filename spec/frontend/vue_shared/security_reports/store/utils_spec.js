import { enrichVulnerabilityWithFeedback } from '~/vue_shared/security_reports/store/utils';
import {
  FEEDBACK_TYPE_DISMISSAL,
  FEEDBACK_TYPE_ISSUE,
  FEEDBACK_TYPE_MERGE_REQUEST,
} from '~/vue_shared/security_reports/constants';

describe('security reports store utils', () => {
  const vulnerability = { uuid: 1 };

  describe('enrichVulnerabilityWithFeedback', () => {
    const dismissalFeedback = {
      feedback_type: FEEDBACK_TYPE_DISMISSAL,
      finding_uuid: vulnerability.uuid,
    };
    const dismissalVuln = { ...vulnerability, isDismissed: true, dismissalFeedback };

    const issueFeedback = {
      feedback_type: FEEDBACK_TYPE_ISSUE,
      issue_iid: 1,
      finding_uuid: vulnerability.uuid,
    };
    const issueVuln = { ...vulnerability, hasIssue: true, issue_feedback: issueFeedback };
    const mrFeedback = {
      feedback_type: FEEDBACK_TYPE_MERGE_REQUEST,
      merge_request_iid: 1,
      finding_uuid: vulnerability.uuid,
    };
    const mrVuln = {
      ...vulnerability,
      hasMergeRequest: true,
      merge_request_feedback: mrFeedback,
    };

    it.each`
      feedbacks                                         | expected
      ${[dismissalFeedback]}                            | ${dismissalVuln}
      ${[{ ...issueFeedback, issue_iid: null }]}        | ${vulnerability}
      ${[issueFeedback]}                                | ${issueVuln}
      ${[{ ...mrFeedback, merge_request_iid: null }]}   | ${vulnerability}
      ${[mrFeedback]}                                   | ${mrVuln}
      ${[dismissalFeedback, issueFeedback, mrFeedback]} | ${{ ...dismissalVuln, ...issueVuln, ...mrVuln }}
    `('returns expected enriched vulnerability: $expected', ({ feedbacks, expected }) => {
      const enrichedVulnerability = enrichVulnerabilityWithFeedback(vulnerability, feedbacks);

      expect(enrichedVulnerability).toEqual(expected);
    });

    it('matches correct feedback objects to vulnerability', () => {
      const feedbacks = [
        dismissalFeedback,
        issueFeedback,
        mrFeedback,
        { ...dismissalFeedback, finding_uuid: 2 },
        { ...issueFeedback, finding_uuid: 2 },
        { ...mrFeedback, finding_uuid: 2 },
      ];
      const enrichedVulnerability = enrichVulnerabilityWithFeedback(vulnerability, feedbacks);

      expect(enrichedVulnerability).toEqual({ ...dismissalVuln, ...issueVuln, ...mrVuln });
    });
  });
});
