import { getByText } from '@testing-library/dom';
import htmlOpenIssue from 'test_fixtures/issues/open-issue.html';
import htmlClosedIssue from 'test_fixtures/issues/closed-issue.html';
import MockAdapter from 'axios-mock-adapter';
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
  const getOpenStatusBox = () =>
    getByText(document, (_, el) => el.textContent.match(/Open/), {
      selector: '.issuable-status-badge-open',
    });
  const getClosedStatusBox = () =>
    getByText(document, (_, el) => el.textContent.match(/Closed/), {
      selector: '.issuable-status-badge-closed',
    });

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
      testContext.statusBoxClosed = getClosedStatusBox();
      testContext.statusBoxOpen = getOpenStatusBox();

      testContext.issueCounter.textContent = '1,001';
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it(`has the proper visible status box when ${isIssueInitiallyOpen ? 'open' : 'closed'}`, () => {
      if (isIssueInitiallyOpen) {
        expect(testContext.statusBoxClosed).toHaveClass('hidden');
        expect(testContext.statusBoxOpen).not.toHaveClass('hidden');
      } else {
        expect(testContext.statusBoxClosed).not.toHaveClass('hidden');
        expect(testContext.statusBoxOpen).toHaveClass('hidden');
      }
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

      it('displays correct status box', () => {
        if (isIssueInitiallyOpen) {
          expect(testContext.statusBoxClosed).not.toHaveClass('hidden');
          expect(testContext.statusBoxOpen).toHaveClass('hidden');
        } else {
          expect(testContext.statusBoxClosed).toHaveClass('hidden');
          expect(testContext.statusBoxOpen).not.toHaveClass('hidden');
        }
      });

      it('updates issueCounter text', () => {
        expect(testContext.issueCounter).toBeVisible();
        expect(testContext.issueCounter).toHaveText(expectedCounterText);
      });
    });
  });
});
