import { getByText } from '@testing-library/dom';
import MockAdapter from 'axios-mock-adapter';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import Issue from '~/issue';
import axios from '~/lib/utils/axios_utils';

describe('Issue', () => {
  let testContext;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(/(.*)\/related_branches$/).reply(200, {});

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
      selector: '.status-box-open',
    });
  const getClosedStatusBox = () =>
    getByText(document, (_, el) => el.textContent.match(/Closed/), {
      selector: '.status-box-issue-closed',
    });

  describe.each`
    desc                                | isIssueInitiallyOpen | expectedCounterText
    ${'with an initially open issue'}   | ${true}              | ${'1,000'}
    ${'with an initially closed issue'} | ${false}             | ${'1,002'}
  `('$desc', ({ isIssueInitiallyOpen, expectedCounterText }) => {
    beforeEach(() => {
      if (isIssueInitiallyOpen) {
        loadFixtures('issues/open-issue.html');
      } else {
        loadFixtures('issues/closed-issue.html');
      }

      testContext.issueCounter = getIssueCounter();
      testContext.statusBoxClosed = getClosedStatusBox();
      testContext.statusBoxOpen = getOpenStatusBox();

      testContext.issueCounter.textContent = '1,001';
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
