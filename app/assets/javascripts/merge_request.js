/* eslint-disable func-names, no-underscore-dangle, consistent-return */

import $ from 'jquery';
import { __ } from '~/locale';
import createFlash from '~/flash';
import TaskList from './task_list';
import MergeRequestTabs from './merge_request_tabs';
import IssuablesHelper from './helpers/issuables_helper';
import { addDelimiter } from './lib/utils/text_utility';

function MergeRequest(opts) {
  // Initialize MergeRequest behavior
  //
  // Options:
  //   action - String, current controller action
  //
  this.opts = opts != null ? opts : {};
  this.submitNoteForm = this.submitNoteForm.bind(this);
  this.$el = $('.merge-request');
  this.$('.show-all-commits').on('click', () => this.showAllCommits());

  this.initTabs();
  this.initMRBtnListeners();
  this.initCommitMessageListeners();
  this.closeReopenReportToggle = IssuablesHelper.initCloseReopenReport();

  if ($('a.btn-close').length) {
    this.taskList = new TaskList({
      dataType: 'merge_request',
      fieldName: 'description',
      selector: '.detail-page-description',
      lockVersion: this.$el.data('lockVersion'),
      onSuccess: result => {
        document.querySelector('#task_status').innerText = result.task_status;
        document.querySelector('#task_status_short').innerText = result.task_status_short;
      },
      onError: () => {
        createFlash(
          __(
            'Someone edited this merge request at the same time you did. Please refresh the page to see changes.',
          ),
        );
      },
    });
  }
}

// Local jQuery finder
MergeRequest.prototype.$ = function(selector) {
  return this.$el.find(selector);
};

MergeRequest.prototype.initTabs = function() {
  if (window.mrTabs) {
    window.mrTabs.unbindEvents();
  }

  window.mrTabs = new MergeRequestTabs(this.opts);
};

MergeRequest.prototype.showAllCommits = function() {
  this.$('.first-commits').remove();
  return this.$('.all-commits').removeClass('hide');
};

MergeRequest.prototype.initMRBtnListeners = function() {
  const _this = this;
  return $('a.btn-close, a.btn-reopen').on('click', function(e) {
    const $this = $(this);
    const shouldSubmit = $this.hasClass('btn-comment');
    if (shouldSubmit && $this.data('submitted')) {
      return;
    }

    if (this.closeReopenReportToggle) this.closeReopenReportToggle.setDisable();

    if (shouldSubmit) {
      if ($this.hasClass('btn-comment-and-close') || $this.hasClass('btn-comment-and-reopen')) {
        e.preventDefault();
        e.stopImmediatePropagation();

        _this.submitNoteForm($this.closest('form'), $this);
      }
    }
  });
};

MergeRequest.prototype.submitNoteForm = function(form, $button) {
  const noteText = form.find('textarea.js-note-text').val();
  if (noteText.trim().length > 0) {
    form.submit();
    $button.data('submitted', true);
    return $button.trigger('click');
  }
};

MergeRequest.prototype.initCommitMessageListeners = function() {
  $(document).on('click', 'a.js-with-description-link', e => {
    const textarea = $('textarea.js-commit-message');
    e.preventDefault();

    textarea.val(textarea.data('messageWithDescription'));
    $('.js-with-description-hint').hide();
    $('.js-without-description-hint').show();
  });

  $(document).on('click', 'a.js-without-description-link', e => {
    const textarea = $('textarea.js-commit-message');
    e.preventDefault();

    textarea.val(textarea.data('messageWithoutDescription'));
    $('.js-with-description-hint').show();
    $('.js-without-description-hint').hide();
  });
};

MergeRequest.setStatusBoxToMerged = function() {
  $('.detail-page-header .status-box')
    .removeClass('status-box-open')
    .addClass('status-box-mr-merged')
    .find('span')
    .text(__('Merged'));
};

MergeRequest.decreaseCounter = function(by = 1) {
  const $el = $('.js-merge-counter');
  const count = Math.max(parseInt($el.text().replace(/[^\d]/, ''), 10) - by, 0);

  $el.text(addDelimiter(count));
};

MergeRequest.hideCloseButton = function() {
  const el = document.querySelector('.merge-request .js-issuable-actions');
  const closeDropdownItem = el.querySelector('li.close-item');
  if (closeDropdownItem) {
    closeDropdownItem.classList.add('hidden');
    // Selects the next dropdown item
    el.querySelector('li.report-item').click();
  } else {
    // No dropdown just hide the Close button
    el.querySelector('.btn-close').classList.add('hidden');
  }
  // Dropdown for mobile screen
  el.querySelector('li.js-close-item').classList.add('hidden');
};

export default MergeRequest;
