import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Issue from '~/issue';
import '~/lib/utils/text_utility';

describe('Issue', () => {
  let $boxClosed;
  let $boxOpen;
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  preloadFixtures('issues/closed-issue.html');
  preloadFixtures('issues/open-issue.html');

  function expectVisibility($element, shouldBeVisible) {
    if (shouldBeVisible) {
      expect($element).not.toHaveClass('hidden');
    } else {
      expect($element).toHaveClass('hidden');
    }
  }

  function expectIssueState(isIssueOpen) {
    expectVisibility($boxClosed, !isIssueOpen);
    expectVisibility($boxOpen, isIssueOpen);
  }

  function findElements() {
    $boxClosed = $('div.status-box-issue-closed');

    expect($boxClosed).toExist();
    expect($boxClosed).toHaveText('Closed');

    $boxOpen = $('div.status-box-open');

    expect($boxOpen).toExist();
    expect($boxOpen).toHaveText('Open');
  }

  [true, false].forEach(isIssueInitiallyOpen => {
    describe(`with ${isIssueInitiallyOpen ? 'open' : 'closed'} issue`, () => {
      const action = isIssueInitiallyOpen ? 'close' : 'reopen';
      let mock;

      function setup() {
        testContext.issue = new Issue();
        expectIssueState(isIssueInitiallyOpen);

        testContext.$projectIssuesCounter = $('.issue_counter').first();
        testContext.$projectIssuesCounter.text('1,001');
      }

      beforeEach(() => {
        if (isIssueInitiallyOpen) {
          loadFixtures('issues/open-issue.html');
        } else {
          loadFixtures('issues/closed-issue.html');
        }

        mock = new MockAdapter(axios);
        mock.onGet(/(.*)\/related_branches$/).reply(200, {});
        jest.spyOn(axios, 'get');

        findElements(isIssueInitiallyOpen);
      });

      afterEach(() => {
        mock.restore();
        $('div.flash-alert').remove();
      });

      it(`${action}s the issue on dispatch of issuable_vue_app:change event`, () => {
        setup();

        document.dispatchEvent(
          new CustomEvent('issuable_vue_app:change', {
            detail: {
              data: { id: 1 },
              isClosed: isIssueInitiallyOpen,
            },
          }),
        );

        expectIssueState(!isIssueInitiallyOpen);
      });
    });
  });
});
