/* eslint-disable one-var, no-use-before-define */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Issue from '~/issue';
import '~/lib/utils/text_utility';

describe('Issue', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  let $boxClosed, $boxOpen;

  preloadFixtures('issues/closed-issue.html');
  preloadFixtures('issues/issue-with-task-list.html');
  preloadFixtures('issues/open-issue.html');
  preloadFixtures('static/issue_with_mermaid_graph.html');

  function expectIssueState(isIssueOpen) {
    expectVisibility($boxClosed, !isIssueOpen);
    expectVisibility($boxOpen, isIssueOpen);
  }

  function expectVisibility($element, shouldBeVisible) {
    if (shouldBeVisible) {
      expect($element).not.toHaveClass('hidden');
    } else {
      expect($element).toHaveClass('hidden');
    }
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

  describe('when not displaying blocked warning', () => {
    describe('when clicking a mermaid graph inside an issue description', () => {
      let mock;
      let spy;

      beforeEach(() => {
        loadFixtures('static/issue_with_mermaid_graph.html');
        mock = new MockAdapter(axios);
        spy = jest.spyOn(axios, 'put');
      });

      afterEach(() => {
        mock.restore();
        jest.clearAllMocks();
      });

      it('does not make a PUT request', () => {
        Issue.prototype.initIssueBtnEventListeners();

        $('svg a.js-issuable-actions').trigger('click');

        expect(spy).not.toHaveBeenCalled();
      });
    });
  });
});
