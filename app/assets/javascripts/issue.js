/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, no-underscore-dangle, one-var-declaration-per-line, object-shorthand, no-unused-vars, no-new, comma-dangle, consistent-return, quotes, dot-notation, quote-props, prefer-arrow-callback, max-len */
/* global Flash */
/* global Issuable */

require('./flash');
require('~/lib/utils/text_utility');
require('vendor/jquery.waitforimages');
require('./task_list');

class Issue {
  constructor() {
    if ($('a.btn-close').length) {
      const closeButtons = $('a.btn-close');
      const isClosedBadge = $('div.status-box-closed');
      const isOpenBadge = $('div.status-box-open');
      const projectIssuesCounter = $('.issue_counter');
      const reopenButtons = $('a.btn-reopen');

      this.taskList = new gl.TaskList({
        dataType: 'issue',
        fieldName: 'description',
        selector: '.detail-page-description',
        onSuccess: (result) => {
          document.querySelector('#task_status').innerText = result.task_status;
          document.querySelector('#task_status_short').innerText = result.task_status_short;
        }
      });

      Issuable.initStateChangeButton({
        type: 'issue',
        beforeSend() {
          Issue.setNewBranchButtonState(true, null);
        },
        errorCallback() {
          Issue.initCanCreateBranch();
        },
        callback(data, $btn) {
          const isClosed = data.state === 'closed';

          $btn.enable();
          $(document).trigger('issuable:change');

          closeButtons.toggleClass('hidden', isClosed);
          reopenButtons.toggleClass('hidden', !isClosed);
          isClosedBadge.toggleClass('hidden', !isClosed);
          isOpenBadge.toggleClass('hidden', isClosed);

          let numProjectIssues = Number(projectIssuesCounter.text().replace(/[^\d]/, ''));
          numProjectIssues = isClosed ? numProjectIssues - 1 : numProjectIssues + 1;

          projectIssuesCounter.text(gl.text.addDelimiter(numProjectIssues));

          Issue.initCanCreateBranch();
        },
      });
    }

    Issue.$btnNewBranch = $('#new-branch');

    Issue.initMergeRequests();
    Issue.initRelatedBranches();
    Issue.initCanCreateBranch();
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

  static initCanCreateBranch() {
    // If the user doesn't have the required permissions the container isn't
    // rendered at all.
    if (Issue.$btnNewBranch.length === 0) {
      return;
    }
    return $.getJSON(Issue.$btnNewBranch.data('path')).fail(function() {
      Issue.setNewBranchButtonState(false, false);
      new Flash('Failed to check if a new branch can be created.');
    }).done(function(data) {
      Issue.setNewBranchButtonState(false, data.can_create_branch);
    });
  }

  static setNewBranchButtonState(isPending, canCreate) {
    if (Issue.$btnNewBranch.length === 0) {
      return;
    }

    Issue.$btnNewBranch.find('.available').toggle(!isPending && canCreate);
    Issue.$btnNewBranch.find('.unavailable').toggle(!isPending && !canCreate);
  }
}

export default Issue;
