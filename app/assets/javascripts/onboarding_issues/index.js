import $ from 'jquery';
import { parseBoolean, getCookie, setCookie, removeCookie } from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import Tracking from '~/tracking';

const COOKIE_NAME = 'onboarding_issues_settings';

const POPOVER_LOCATIONS = {
  GROUPS_SHOW: 'groups#show',
  PROJECTS_SHOW: 'projects#show',
  ISSUES_INDEX: 'issues#index',
};

const removeLearnGitLabCookie = () => {
  removeCookie(COOKIE_NAME);
};

function disposePopover(event) {
  event.preventDefault();
  this.popover('dispose');
  removeLearnGitLabCookie();
  Tracking.event('Growth::Conversion::Experiment::OnboardingIssues', 'dismiss_popover');
}

const showPopover = (el, path, footer, options) => {
  // Cookie value looks like `{ 'groups#show': true, 'projects#show': true, 'issues#index': true }`. When it doesn't exist, don't show the popover.
  const cookie = getCookie(COOKIE_NAME);
  if (!cookie) return;

  // When the popover action has already been taken, don't show the popover.
  const settings = JSON.parse(cookie);
  if (!parseBoolean(settings[path])) return;

  const defaultOptions = {
    boundary: 'window',
    html: true,
    placement: 'top',
    template: `<div class="popover blue learn-gitlab d-none d-xl-block" role="tooltip">
                <div class="arrow"></div>
                <div class="close cursor-pointer gl-font-base text-white gl-opacity-10 p-2">&#10005</div>
                <div class="popover-body gl-font-base gl-line-height-20 pb-0 px-3"></div>
                <div class="bold text-right text-white p-2">${footer}</div>
               </div>`,
  };

  // When one of the popovers is dismissed, remove the cookie.
  const closeButton = () => document.querySelector('.learn-gitlab.popover .close');

  // We still have to use jQuery, since Bootstrap's Popover is based on jQuery.
  const jQueryEl = $(el);
  const clickCloseButton = disposePopover.bind(jQueryEl);

  jQueryEl
    .popover({ ...defaultOptions, ...options })
    .on('inserted.bs.popover', () => closeButton().addEventListener('click', clickCloseButton))
    .on('hide.bs.dropdown', () => closeButton().removeEventListener('click', clickCloseButton))
    .popover('show');

  // The previous popover actions have been taken, don't show those popovers anymore.
  Object.keys(settings).forEach(pathSetting => {
    if (path !== pathSetting) {
      settings[pathSetting] = false;
    } else {
      setCookie(COOKIE_NAME, settings);
    }
  });

  // The final popover action will be taken on click, we then no longer need the cookie.
  if (path === POPOVER_LOCATIONS.ISSUES_INDEX) {
    el.addEventListener('click', removeLearnGitLabCookie);
  }
};

export const showLearnGitLabGroupItemPopover = id => {
  const el = document.querySelector(`#group-${id} .group-text a`);

  if (!el) return;

  const options = {
    content: __(
      'Here are all your projects in your group, including the one you just created. To start, let’s take a look at your personalized learning project which will help you learn about GitLab at your own pace.',
    ),
  };

  showPopover(el, POPOVER_LOCATIONS.GROUPS_SHOW, '1 / 2', options);
};

export const showLearnGitLabProjectPopover = () => {
  // Do not show a popover if we are not viewing the 'Learn GitLab' project.
  if (!window.location.pathname.includes('learn-gitlab')) return;

  const el = document.querySelector('a.shortcuts-issues');

  if (!el) return;

  const options = {
    content: sprintf(
      __(
        'Go to %{strongStart}Issues%{strongEnd} &gt; %{strongStart}Boards%{strongEnd} to access your personalized learning issue board.',
      ),
      { strongStart: '<strong>', strongEnd: '</strong>' },
      false,
    ),
  };

  showPopover(el, POPOVER_LOCATIONS.PROJECTS_SHOW, '2 / 2', options);
};

export const showLearnGitLabIssuesPopover = () => {
  // Do not show a popover if we are not viewing the 'Learn GitLab' project.
  if (!window.location.pathname.includes('learn-gitlab')) return;

  const el = document.querySelector('a[data-qa-selector="issue_boards_link"]');

  if (!el) return;

  const options = {
    content: sprintf(
      __(
        'Go to %{strongStart}Issues%{strongEnd} &gt; %{strongStart}Boards%{strongEnd} to access your personalized learning issue board.',
      ),
      { strongStart: '<strong>', strongEnd: '</strong>' },
      false,
    ),
  };

  showPopover(el, POPOVER_LOCATIONS.ISSUES_INDEX, '2 / 2', options);
};
