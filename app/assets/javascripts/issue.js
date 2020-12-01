import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import { addDelimiter } from './lib/utils/text_utility';
import { deprecatedCreateFlash as flash } from './flash';
import CreateMergeRequestDropdown from './create_merge_request_dropdown';
import { joinPaths } from '~/lib/utils/url_utility';
import { __ } from './locale';

export default class Issue {
  constructor() {
    if ($('.js-alert-moved-from-service-desk-warning').length) {
      Issue.initIssueMovedFromServiceDeskDismissHandler();
    }

    if (document.querySelector('#related-branches')) {
      Issue.initRelatedBranches();
    }

    Issue.createMrDropdownWrap = document.querySelector('.create-mr-dropdown-wrap');

    if (Issue.createMrDropdownWrap) {
      this.createMergeRequestDropdown = new CreateMergeRequestDropdown(Issue.createMrDropdownWrap);
    }

    // Listen to state changes in the Vue app
    document.addEventListener('issuable_vue_app:change', event => {
      this.updateTopState(event.detail.isClosed, event.detail.data);
    });
  }

  /**
   * This method updates the top area of the issue.
   *
   * Once the issue state changes, either through a click on the top area (jquery)
   * or a click on the bottom area (Vue) we need to update the top area.
   *
   * @param {Boolean} isClosed
   * @param {Array} data
   * @param {String} issueFailMessage
   */
  updateTopState(
    isClosed,
    data,
    issueFailMessage = __('Unable to update this issue at this time.'),
  ) {
    if ('id' in data) {
      const isClosedBadge = $('div.status-box-issue-closed');
      const isOpenBadge = $('div.status-box-open');
      const projectIssuesCounter = $('.issue_counter');

      isClosedBadge.toggleClass('hidden', !isClosed);
      isOpenBadge.toggleClass('hidden', isClosed);

      $(document).trigger('issuable:change', isClosed);

      let numProjectIssues = Number(
        projectIssuesCounter
          .first()
          .text()
          .trim()
          .replace(/[^\d]/, ''),
      );
      numProjectIssues = isClosed ? numProjectIssues - 1 : numProjectIssues + 1;
      projectIssuesCounter.text(addDelimiter(numProjectIssues));

      if (this.createMergeRequestDropdown) {
        this.createMergeRequestDropdown.checkAbilityToCreateBranch();
      }
    } else {
      flash(issueFailMessage);
    }
  }

  static initIssueMovedFromServiceDeskDismissHandler() {
    const alertMovedFromServiceDeskWarning = $('.js-alert-moved-from-service-desk-warning');

    const trimmedPathname = window.location.pathname.slice(1);
    const alertMovedFromServiceDeskDismissedKey = joinPaths(
      trimmedPathname,
      'alert-issue-moved-from-service-desk-dismissed',
    );

    if (!localStorage.getItem(alertMovedFromServiceDeskDismissedKey)) {
      alertMovedFromServiceDeskWarning.show();
    }

    alertMovedFromServiceDeskWarning.on('click', '.js-close', e => {
      e.preventDefault();
      e.stopImmediatePropagation();
      alertMovedFromServiceDeskWarning.remove();
      localStorage.setItem(alertMovedFromServiceDeskDismissedKey, true);
    });
  }

  static initRelatedBranches() {
    const $container = $('#related-branches');
    axios
      .get($container.data('url'))
      .then(({ data }) => {
        if ('html' in data) {
          $container.html(data.html);
        }
      })
      .catch(() => flash(__('Failed to load related branches')));
  }
}
