import TaskList from './task_list';
import MergeRequestTabs from './merge_request_tabs';
import IssuablesHelper from './helpers/issuables_helper';

export default class MergeRequest {
  constructor(opts = {}) {
    // Initialize MergeRequest behavior
    //
    // Options:
    //   action - String, current controller action
    //
    this.opts = opts;
    this.$el = $('.merge-request');
    this.$el.find('.show-all-commits').on('click', () => this.showAllCommits());

    this.initTabs();
    MergeRequest.initMRBtnListeners();
    MergeRequest.initCommitMessageListeners();
    this.closeReopenReportToggle = IssuablesHelper.initCloseReopenReport();

    if ($('a.btn-close').length) {
      this.taskList = new TaskList({
        dataType: 'merge_request',
        fieldName: 'description',
        selector: '.detail-page-description',
        onSuccess: (result) => {
          document.querySelector('#task_status').innerText = result.task_status;
          document.querySelector('#task_status_short').innerText = result.task_status_short;
        },
      });
    }
  }

  initTabs() {
    if (window.mrTabs) {
      window.mrTabs.unbindEvents();
    }
    window.mrTabs = new MergeRequestTabs(this.opts);
  }

  showAllCommits() {
    this.$el.find('.first-commits').remove();
    this.$el.find('.all-commits').removeClass('hide');
  }

  static initMRBtnListeners() {
    return $('a.btn-close, a.btn-reopen').on('click', function onBtnClick(e) {
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

          MergeRequest.submitNoteForm($this.closest('form'), $this);
        }
      }
    });
  }

  static submitNoteForm(form, $button) {
    const noteText = form.find('textarea.js-note-text').val();
    if (noteText.trim().length > 0) {
      form.submit();
      $button.data('submitted', true);
      $button.trigger('click');
    }
  }

  static initCommitMessageListeners() {
    $(document).on('click', 'a.js-with-description-link', (e) => {
      e.preventDefault();
      const textarea = $('textarea.js-commit-message');
      textarea.val(textarea.data('messageWithDescription'));
      $('.js-with-description-hint').hide();
      $('.js-without-description-hint').show();
    });

    $(document).on('click', 'a.js-without-description-link', (e) => {
      e.preventDefault();
      const textarea = $('textarea.js-commit-message');
      textarea.val(textarea.data('messageWithoutDescription'));
      $('.js-with-description-hint').show();
      $('.js-without-description-hint').hide();
    });
  }

  static updateStatusText(classToRemove, classToAdd, newStatusText) {
    $('.detail-page-header .status-box')
      .removeClass(classToRemove)
      .addClass(classToAdd)
      .find('span')
      .text(newStatusText);
  }

  static decreaseCounter(by = 1) {
    const $el = $('.nav-links .js-merge-counter');
    const count = Math.max((parseInt($el.text().replace(/[^\d]/, ''), 10) - by), 0);

    $el.text(gl.text.addDelimiter(count));
  }

  static hideCloseButton() {
    const el = document.querySelector('.merge-request .issuable-actions');
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
  }
}
