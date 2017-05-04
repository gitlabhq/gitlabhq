/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, no-underscore-dangle, one-var-declaration-per-line, object-shorthand, no-unused-vars, no-new, comma-dangle, consistent-return, quotes, dot-notation, quote-props, prefer-arrow-callback, max-len */
 /* global Flash */
import CreateMergeRequestDropdown from './create_merge_request_dropdown';

require('./flash');
require('~/lib/utils/text_utility');
require('vendor/jquery.waitforimages');
require('./task_list');

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

    if (Issue.createMrDropdownWrap) {
      this.createMergeRequestDropdown = new CreateMergeRequestDropdown(Issue.createMrDropdownWrap);
    }
  }

  initIssueBtnEventListeners() {
    const issueFailMessage = 'Unable to update this issue at this time.';
    const closeButtons = $('a.btn-close');
    const isClosedBadge = $('div.status-box-closed');
    const isOpenBadge = $('div.status-box-open');
    const projectIssuesCounter = $('.issue_counter');
    const reopenButtons = $('a.btn-reopen');

    return closeButtons.add(reopenButtons).on('click', (e) => {
      var $button, shouldSubmit, url;
      e.preventDefault();
      e.stopImmediatePropagation();
      $button = $(e.currentTarget);
      shouldSubmit = $button.hasClass('btn-comment');
      if (shouldSubmit) {
        Issue.submitNoteForm($button.closest('form'));
      }
      $button.prop('disabled', true);
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
          closeButtons.toggleClass('hidden', isClosed);
          reopenButtons.toggleClass('hidden', !isClosed);
          isClosedBadge.toggleClass('hidden', !isClosed);
          isOpenBadge.toggleClass('hidden', isClosed);

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

        $button.prop('disabled', false);
      });
    });
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
