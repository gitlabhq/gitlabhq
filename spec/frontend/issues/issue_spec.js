import MockAdapter from 'axios-mock-adapter';
import htmlOpenIssue from 'test_fixtures/issues/open-issue.html';
import htmlClosedIssue from 'test_fixtures/issues/closed-issue.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import Issue from '~/issues/issue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Issue', () => {
  let testContext;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(/(.*)\/related_branches$/).reply(HTTP_STATUS_OK, {});

    testContext = {};
    testContext.issue = new Issue();
  });

  afterEach(() => {
    mock.restore();
    testContext.issue.dispose();
  });

  const getIssueCounter = () => document.querySelector('.issue_counter');

  describe.each`
    desc                                | isIssueInitiallyOpen | expectedCounterText
    ${'with an initially open issue'}   | ${true}              | ${'1,000'}
    ${'with an initially closed issue'} | ${false}             | ${'1,002'}
  `('$desc', ({ isIssueInitiallyOpen, expectedCounterText }) => {
    beforeEach(() => {
      if (isIssueInitiallyOpen) {
        setHTMLFixture(htmlOpenIssue);
      } else {
        setHTMLFixture(htmlClosedIssue);
      }

      testContext.issueCounter = getIssueCounter();
      testContext.issueCounter.textContent = '1,001';
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    describe('when vue app triggers change', () => {
      beforeEach(() => {
        document.dispatchEvent(
          new CustomEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, {
            detail: {
              data: { id: 1 },
              isClosed: isIssueInitiallyOpen,
            },
          }),
        );
      });

      // TODO: Remove this with the removal of the old navigation.
      // See https://gitlab.com/groups/gitlab-org/-/epics/11875.
      // See also https://gitlab.com/gitlab-org/gitlab/-/issues/429678 about
      // reimplementing this in the new navigation.
      //
      // Since this entire suite only tests the issue count updating, removing
      // this test would mean removing the entire suite. But, ~/issues/issue.js
      // does more than just that. Tests should be written to cover those other
      // features. So we're just skipping this for now.
      // eslint-disable-next-line jest/no-disabled-tests
      it.skip('updates issueCounter text', () => {
        expect(testContext.issueCounter).toBeVisible();
        expect(testContext.issueCounter).toHaveText(expectedCounterText);
      });
    });
  });
});
