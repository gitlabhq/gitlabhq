/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, no-underscore-dangle, one-var-declaration-per-line, object-shorthand, no-unused-vars, no-new, comma-dangle, consistent-return, quotes, dot-notation, quote-props, prefer-arrow-callback, max-len */

import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import { addDelimiter } from './lib/utils/text_utility';
import flash from './flash';
import TaskList from './task_list';
import CreateMergeRequestDropdown from './create_merge_request_dropdown';
import IssuablesHelper from './helpers/issuables_helper';

export default class Issue {
  constructor() {
    if ($('a.btn-close').length) this.initIssueBtnEventListeners();

    Issue.$btnNewBranch = $('#new-branch');
    Issue.createMrDropdownWrap = document.querySelector('.create-mr-dropdown-wrap');

    Issue.initMergeRequests();
    Issue.initRelatedBranches();

    this.closeButtons = $('a.btn-close');
    this.reopenButtons = $('a.btn-reopen');

    this.initCloseReopenReport();

    if (Issue.createMrDropdownWrap) {
      this.createMergeRequestDropdown = new CreateMergeRequestDropdown(Issue.createMrDropdownWrap);
    }

    // Listen to state changes in the Vue app
    document.addEventListener('issuable_vue_app:change', (event) => {
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
  updateTopState(isClosed, data, issueFailMessage = 'Unable to update this issue at this time.') {
    if ('id' in data) {
      const isClosedBadge = $('div.status-box-issue-closed');
      const isOpenBadge = $('div.status-box-open');
      const projectIssuesCounter = $('.issue_counter');

      isClosedBadge.toggleClass('hidden', !isClosed);
      isOpenBadge.toggleClass('hidden', isClosed);

      $(document).trigger('issuable:change', isClosed);
      this.toggleCloseReopenButton(isClosed);

      let numProjectIssues = Number(projectIssuesCounter.first().text().trim().replace(/[^\d]/, ''));
      numProjectIssues = isClosed ? numProjectIssues - 1 : numProjectIssues + 1;
      projectIssuesCounter.text(addDelimiter(numProjectIssues));

      if (this.createMergeRequestDropdown) {
        if (isClosed) {
          this.createMergeRequestDropdown.unavailable();
          this.createMergeRequestDropdown.disable();
        } else {
          // We should check in case a branch was created in another tab
          this.createMergeRequestDropdown.checkAbilityToCreateBranch();
        }
      }
    } else {
      flash(issueFailMessage);
    }
  }

  initIssueBtnEventListeners() {
    const issueFailMessage = 'Unable to update this issue at this time.';

    return $(document).on('click', '.js-issuable-actions a.btn-close, .js-issuable-actions a.btn-reopen', (e) => {
      var $button, shouldSubmit, url;
      e.preventDefault();
      e.stopImmediatePropagation();
      $button = $(e.currentTarget);
      shouldSubmit = $button.hasClass('btn-comment');
      if (shouldSubmit) {
        Issue.submitNoteForm($button.closest('form'));
      }

      this.disableCloseReopenButton($button);

      url = $button.attr('href');
      return axios.put(url)
      .then(({ data }) => {
        const isClosed = $button.hasClass('btn-close');
        this.updateTopState(isClosed, data);
      })
      .catch(() => flash(issueFailMessage))
      .then(() => {
        this.disableCloseReopenButton($button, false);
      });
    });
  }

  initCloseReopenReport() {
    this.closeReopenReportToggle = IssuablesHelper.initCloseReopenReport();

    if (this.closeButtons) this.closeButtons = this.closeButtons.not('.issuable-close-button');
    if (this.reopenButtons) this.reopenButtons = this.reopenButtons.not('.issuable-close-button');
  }

  disableCloseReopenButton($button, shouldDisable) {
    if (this.closeReopenReportToggle) {
      this.closeReopenReportToggle.setDisable(shouldDisable);
    } else {
      $button.prop('disabled', shouldDisable);
    }
  }

  toggleCloseReopenButton(isClosed) {
    if (this.closeReopenReportToggle) this.closeReopenReportToggle.updateButton(isClosed);
    this.closeButtons.toggleClass('hidden', isClosed);
    this.reopenButtons.toggleClass('hidden', !isClosed);
  }

  static submitNoteForm(form) {
    var noteText;
    noteText = form.find("textarea.js-note-text").val();
    if (noteText && noteText.trim().length > 0) {
      return form.submit();
    }
  }

  static initMergeRequests() {
    var $container;
    $container = $('#merge-requests');
    return axios.get($container.data('url'))
      .then(({ data }) => {
        if ('html' in data) {
          $container.html(data.html);
        }
      }).catch(() => flash('Failed to load referenced merge requests'));
  }

  static initRelatedBranches() {
    var $container;
    $container = $('#related-branches');
    return axios.get($container.data('url'))
      .then(({ data }) => {
        if ('html' in data) {
          $container.html(data.html);
        }
      }).catch(() => flash('Failed to load related branches'));
  }
}
