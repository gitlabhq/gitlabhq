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

  let $boxClosed, $boxOpen, $btn;

  preloadFixtures('issues/closed-issue.html');
  preloadFixtures('issues/issue-with-task-list.html');
  preloadFixtures('issues/open-issue.html');

  function expectErrorMessage() {
    const $flashMessage = $('div.flash-alert');

    expect($flashMessage).toExist();
    expect($flashMessage).toBeVisible();
    expect($flashMessage).toHaveText('Unable to update this issue at this time.');
  }

  function expectIssueState(isIssueOpen) {
    expectVisibility($boxClosed, !isIssueOpen);
    expectVisibility($boxOpen, isIssueOpen);

    expect($btn).toHaveText(isIssueOpen ? 'Close issue' : 'Reopen issue');
  }

  function expectNewBranchButtonState(isPending, canCreate) {
    if (Issue.$btnNewBranch.length === 0) {
      return;
    }

    const $available = Issue.$btnNewBranch.find('.available');

    expect($available).toHaveText('New branch');

    if (!isPending && canCreate) {
      expect($available).toBeVisible();
    } else {
      expect($available).toBeHidden();
    }

    const $unavailable = Issue.$btnNewBranch.find('.unavailable');

    expect($unavailable).toHaveText('New branch unavailable');

    if (!isPending && !canCreate) {
      expect($unavailable).toBeVisible();
    } else {
      expect($unavailable).toBeHidden();
    }
  }

  function expectVisibility($element, shouldBeVisible) {
    if (shouldBeVisible) {
      expect($element).not.toHaveClass('hidden');
    } else {
      expect($element).toHaveClass('hidden');
    }
  }

  function findElements(isIssueInitiallyOpen) {
    $boxClosed = $('div.status-box-issue-closed');

    expect($boxClosed).toExist();
    expect($boxClosed).toHaveText('Closed');

    $boxOpen = $('div.status-box-open');

    expect($boxOpen).toExist();
    expect($boxOpen).toHaveText('Open');

    $btn = $('.js-issuable-close-button');

    expect($btn).toExist();
    expect($btn).toHaveText(isIssueInitiallyOpen ? 'Close issue' : 'Reopen issue');
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

      function mockCloseButtonResponseSuccess(url, response) {
        mock.onPut(url).reply(() => {
          expectNewBranchButtonState(true, false);

          return [200, response];
        });
      }

      function mockCloseButtonResponseError(url) {
        mock.onPut(url).networkError();
      }

      function mockCanCreateBranch(canCreateBranch) {
        mock.onGet(/(.*)\/can_create_branch$/).reply(200, {
          can_create_branch: canCreateBranch,
          suggested_branch_name: 'foo-99',
        });
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
        testContext.$triggeredButton = $btn;
      });

      afterEach(() => {
        mock.restore();
        $('div.flash-alert').remove();
      });

      it(`${action}s the issue`, done => {
        mockCloseButtonResponseSuccess(testContext.$triggeredButton.attr('href'), {
          id: 34,
        });
        mockCanCreateBranch(!isIssueInitiallyOpen);

        setup();
        testContext.$triggeredButton.trigger('click');

        setImmediate(() => {
          expectIssueState(!isIssueInitiallyOpen);

          expect(testContext.$triggeredButton.get(0).getAttribute('disabled')).toBeNull();
          expect(testContext.$projectIssuesCounter.text()).toBe(
            isIssueInitiallyOpen ? '1,000' : '1,002',
          );
          expectNewBranchButtonState(false, !isIssueInitiallyOpen);

          done();
        });
      });

      it(`fails to ${action} the issue if saved:false`, done => {
        mockCloseButtonResponseSuccess(testContext.$triggeredButton.attr('href'), {
          saved: false,
        });
        mockCanCreateBranch(isIssueInitiallyOpen);

        setup();
        testContext.$triggeredButton.trigger('click');

        setImmediate(() => {
          expectIssueState(isIssueInitiallyOpen);

          expect(testContext.$triggeredButton.get(0).getAttribute('disabled')).toBeNull();
          expectErrorMessage();

          expect(testContext.$projectIssuesCounter.text()).toBe('1,001');
          expectNewBranchButtonState(false, isIssueInitiallyOpen);

          done();
        });
      });

      it(`fails to ${action} the issue if HTTP error occurs`, done => {
        mockCloseButtonResponseError(testContext.$triggeredButton.attr('href'));
        mockCanCreateBranch(isIssueInitiallyOpen);

        setup();
        testContext.$triggeredButton.trigger('click');

        setImmediate(() => {
          expectIssueState(isIssueInitiallyOpen);

          expect(testContext.$triggeredButton.get(0).getAttribute('disabled')).toBeNull();
          expectErrorMessage();

          expect(testContext.$projectIssuesCounter.text()).toBe('1,001');
          expectNewBranchButtonState(false, isIssueInitiallyOpen);

          done();
        });
      });

      it('disables the new branch button if Ajax call fails', () => {
        mockCloseButtonResponseError(testContext.$triggeredButton.attr('href'));
        mock.onGet(/(.*)\/can_create_branch$/).networkError();

        setup();
        testContext.$triggeredButton.trigger('click');

        expectNewBranchButtonState(false, false);
      });

      it('does not trigger Ajax call if new branch button is missing', done => {
        mockCloseButtonResponseError(testContext.$triggeredButton.attr('href'));

        document.querySelector('#related-branches').remove();
        document.querySelector('.create-mr-dropdown-wrap').remove();

        setup();
        testContext.$triggeredButton.trigger('click');

        setImmediate(() => {
          expect(axios.get).not.toHaveBeenCalled();

          done();
        });
      });
    });
  });
});
