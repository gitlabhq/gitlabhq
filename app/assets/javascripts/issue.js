/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, no-underscore-dangle, one-var-declaration-per-line, object-shorthand, no-unused-vars, no-new, comma-dangle, consistent-return, quotes, dot-notation, quote-props, prefer-arrow-callback, max-len */
/* global Flash */

import 'vendor/jquery.waitforimages';
import '~/lib/utils/text_utility';
import './flash';
import './task_list';
import CreateMergeRequestDropdown from './create_merge_request_dropdown';
import CloseReopenReportToggle from './close_reopen_report_toggle';

class Issue {
  constructor() {
    if ($('a.btn-close').length) {
      this.taskList = new gl.TaskList({
        dataType: 'issue',
        fieldName: 'description',
        selector: '.detail-page-description',
        onSuccess: (result) => {
          document.querySelector('#task_status').innerText = result.task_status;
          document.querySelector('#task_status_short').innerText = result.task_status_short;
        }
      });
      this.initIssueBtnEventListeners();
    }

    Issue.$btnNewBranch = $('#new-branch');
    Issue.createMrDropdownWrap = document.querySelector('.create-mr-dropdown-wrap');

    Issue.initMergeRequests();
    Issue.initRelatedBranches();

    this.initCloseReopenReport();

    if (!this.closeReopenReportToggle) {
      this.closeButtons = $('a.btn-close');
      this.reopenButtons = $('a.btn-reopen');
    }

    if (Issue.createMrDropdownWrap) {
      this.createMergeRequestDropdown = new CreateMergeRequestDropdown(Issue.createMrDropdownWrap);
    }
  }

  initIssueBtnEventListeners() {
    const issueFailMessage = 'Unable to update this issue at this time.';
    const isClosedBadge = $('div.status-box-closed');
    const isOpenBadge = $('div.status-box-open');
    const projectIssuesCounter = $('.issue_counter');

    return $(document).on('click', 'a.btn-close, a.btn-reopen', (e) => {
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
      return $.ajax({
        type: 'PUT',
        url: url
      })
      .fail(() => new Flash(issueFailMessage))
      .done((data) => {
        if ('id' in data) {
          $(document).trigger('issuable:change');

          const isClosed = $button.hasClass('btn-close');
          isClosedBadge.toggleClass('hidden', !isClosed);
          isOpenBadge.toggleClass('hidden', isClosed);

          this.toggleCloseReopenButton(isClosed);

          let numProjectIssues = Number(projectIssuesCounter.text().replace(/[^\d]/, ''));
          numProjectIssues = isClosed ? numProjectIssues - 1 : numProjectIssues + 1;
          projectIssuesCounter.text(gl.text.addDelimiter(numProjectIssues));

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
          new Flash(issueFailMessage);
        }

        this.disableCloseReopenButton($button, false);
      });
    });
  }

  initCloseReopenReport() {
    const container = document.querySelector('.js-issuable-close-dropdown');

    if (!container) return;

    const dropdownTrigger = container.querySelector('.js-issuable-close-toggle');
    const dropdownList = container.querySelector('.js-issuable-close-menu');
    const button = container.querySelector('.js-issuable-close-button');

    this.closeReopenReportToggle = new CloseReopenReportToggle({
      dropdownTrigger,
      dropdownList,
      button,
    });

    this.closeReopenReportToggle.initDroplab();
  }

  disableCloseReopenButton($button, shouldDisable) {
    if (this.closeReopenReportToggle) {
      this.closeReopenReportToggle.setDisable(shouldDisable);
    } else {
      $button.prop('disabled', shouldDisable);
    }
  }

  toggleCloseReopenButton(isClosed) {
    if (this.closeReopenReportToggle) {
      this.closeReopenReportToggle.updateButton(isClosed);
    } else {
      this.closeButtons.toggleClass('hidden', isClosed);
      this.reopenButtons.toggleClass('hidden', !isClosed);
    }
  }

  static submitNoteForm(form) {
    var noteText;
    noteText = form.find("textarea.js-note-text").val();
    if (noteText.trim().length > 0) {
      return form.submit();
    }
  }

  static initMergeRequests() {
    var $container;
    $container = $('#merge-requests');
    return $.getJSON($container.data('url')).fail(function() {
      return new Flash('Failed to load referenced merge requests');
    }).done(function(data) {
      if ('html' in data) {
        return $container.html(data.html);
      }
    });
  }

  static initRelatedBranches() {
    var $container;
    $container = $('#related-branches');
    return $.getJSON($container.data('url')).fail(function() {
      return new Flash('Failed to load related branches');
    }).done(function(data) {
      if ('html' in data) {
        return $container.html(data.html);
      }
    });
  }
}

export default Issue;
