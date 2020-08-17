import $ from 'jquery';
import setWindowLocation from 'helpers/set_window_location_helper';
import { showLearnGitLabIssuesPopover } from '~/onboarding_issues';
import { getCookie, setCookie, removeCookie } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';

describe('Onboarding Issues Popovers', () => {
  const COOKIE_NAME = 'onboarding_issues_settings';
  const getCookieValue = () => JSON.parse(getCookie(COOKIE_NAME));

  beforeEach(() => {
    jest.spyOn($.fn, 'popover');
  });

  afterEach(() => {
    $.fn.popover.mockRestore();
    document.getElementsByTagName('html')[0].innerHTML = '';
    removeCookie(COOKIE_NAME);
  });

  const setupShowLearnGitLabIssuesPopoverTest = ({
    currentPath = 'group/learn-gitlab',
    isIssuesBoardsLinkShown = true,
    isCookieSet = true,
    cookieValue = true,
  } = {}) => {
    setWindowLocation(`http://example.com/${currentPath}`);

    if (isIssuesBoardsLinkShown) {
      const elem = document.createElement('a');
      elem.setAttribute('data-qa-selector', 'issue_boards_link');
      document.body.appendChild(elem);
    }

    if (isCookieSet) {
      setCookie(COOKIE_NAME, { previous: true, 'issues#index': cookieValue });
    }

    showLearnGitLabIssuesPopover();
  };

  describe('showLearnGitLabIssuesPopover', () => {
    describe('when on another project', () => {
      beforeEach(() => {
        setupShowLearnGitLabIssuesPopoverTest({
          currentPath: 'group/another-project',
        });
      });

      it('does not show a popover', () => {
        expect($.fn.popover).not.toHaveBeenCalled();
      });
    });

    describe('when the issues boards link is not shown', () => {
      beforeEach(() => {
        setupShowLearnGitLabIssuesPopoverTest({
          isIssuesBoardsLinkShown: false,
        });
      });

      it('does not show a popover', () => {
        expect($.fn.popover).not.toHaveBeenCalled();
      });
    });

    describe('when the cookie is not set', () => {
      beforeEach(() => {
        setupShowLearnGitLabIssuesPopoverTest({
          isCookieSet: false,
        });
      });

      it('does not show a popover', () => {
        expect($.fn.popover).not.toHaveBeenCalled();
      });
    });

    describe('when the cookie value is false', () => {
      beforeEach(() => {
        setupShowLearnGitLabIssuesPopoverTest({
          cookieValue: false,
        });
      });

      it('does not show a popover', () => {
        expect($.fn.popover).not.toHaveBeenCalled();
      });
    });

    describe('with all the right conditions', () => {
      beforeEach(() => {
        setupShowLearnGitLabIssuesPopoverTest();
      });

      it('shows a popover', () => {
        expect($.fn.popover).toHaveBeenCalled();
      });

      it('does not change the cookie value', () => {
        expect(getCookieValue()['issues#index']).toBe(true);
      });

      it('disables the previous popover', () => {
        expect(getCookieValue().previous).toBe(false);
      });

      describe('when clicking the issues boards link', () => {
        beforeEach(() => {
          document.querySelector('a[data-qa-selector="issue_boards_link"]').click();
        });

        it('deletes the cookie', () => {
          expect(getCookie(COOKIE_NAME)).toBe(undefined);
        });
      });

      describe('when dismissing the popover', () => {
        beforeEach(() => {
          jest.spyOn(Tracking, 'event');
          document.querySelector('.learn-gitlab.popover .close').click();
        });

        it('deletes the cookie', () => {
          expect(getCookie(COOKIE_NAME)).toBe(undefined);
        });

        it('sends a tracking event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(
            'Growth::Conversion::Experiment::OnboardingIssues',
            'dismiss_popover',
          );
        });
      });
    });
  });
});
