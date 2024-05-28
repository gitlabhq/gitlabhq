/* eslint-disable func-names, no-underscore-dangle, consistent-return */

import $ from 'jquery';
import { createAlert } from '~/alert';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import MergeRequestTabs from 'jh_else_ce/merge_request_tabs';
import axios from './lib/utils/axios_utils';
import { addDelimiter } from './lib/utils/text_utility';
import { getParameterValues, setUrlParams } from './lib/utils/url_utility';
import TaskList from './task_list';

function MergeRequest(opts) {
  // Initialize MergeRequest behavior
  //
  // Options:
  //   action - String, current controller action
  //
  this.opts = opts != null ? opts : {};
  this.submitNoteForm = this.submitNoteForm.bind(this);
  this.$el = $('.merge-request');

  this.initTabs();
  this.initMRBtnListeners();

  if ($('.description.js-task-list-container').length) {
    this.taskList = new TaskList({
      dataType: TYPE_MERGE_REQUEST,
      fieldName: 'description',
      selector: '.detail-page-description',
      lockVersion: this.$el.data('lockVersion'),
      onSuccess: (result) => {
        const taskStatus = document.querySelector('#task_status');
        const taskStatusShort = document.querySelector('#task_status_short');

        if (taskStatus) {
          taskStatus.innerText = result.task_status;
        }

        if (taskStatusShort) {
          document.querySelector('#task_status_short').innerText = result.task_status_short;
        }
      },
      onError: () => {
        createAlert({
          message: __(
            'Someone edited this merge request at the same time you did. Please refresh the page to see changes.',
          ),
        });
      },
    });
  }
}

// Local jQuery finder
MergeRequest.prototype.$ = function (selector) {
  return this.$el.find(selector);
};

MergeRequest.prototype.initTabs = function () {
  if (window.mrTabs) {
    window.mrTabs.unbindEvents();
  }

  window.mrTabs = new MergeRequestTabs(this.opts);
};

MergeRequest.prototype.initMRBtnListeners = function () {
  const _this = this;
  const draftToggles = document.querySelectorAll('.js-draft-toggle-button');

  if (draftToggles.length) {
    draftToggles.forEach((draftToggle) => {
      draftToggle.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopImmediatePropagation();

        const url = draftToggle.href;
        const wipEvent = getParameterValues('merge_request[wip_event]', url)[0];
        const mobileDropdown = draftToggle.closest('.dropdown.show');

        const loader = loadingIconForLegacyJS({ inline: true, classes: ['gl-mr-3'] });

        if (mobileDropdown) {
          $(mobileDropdown.firstElementChild).dropdown('toggle');
        }

        draftToggle.setAttribute('disabled', 'disabled');
        draftToggle.prepend(loader);

        axios
          .put(draftToggle.href, null, { params: { format: 'json' } })
          .then(({ data }) => {
            draftToggle.removeAttribute('disabled');

            MergeRequest.toggleDraftStatus(data.title, wipEvent === 'ready');
          })
          .catch(() => {
            createAlert({
              message: __('Something went wrong. Please try again.'),
            });
          })
          .finally(() => {
            draftToggle.removeAttribute('disabled');
            loader.remove();
          });
      });
    });
  }

  return $('.btn-close, .btn-reopen').on('click', function (e) {
    const $this = $(this);
    const shouldSubmit = $this.hasClass('btn-comment');
    if (shouldSubmit && $this.data('submitted')) {
      return;
    }

    if (shouldSubmit) {
      if ($this.hasClass('btn-comment-and-close') || $this.hasClass('btn-comment-and-reopen')) {
        e.preventDefault();
        e.stopImmediatePropagation();

        _this.submitNoteForm($this.closest('form'), $this);
      }
    }
  });
};

MergeRequest.prototype.submitNoteForm = function (form, $button) {
  const noteText = form.find('textarea.js-note-text').val();
  if (noteText.trim().length > 0) {
    form.submit();
    $button.data('submitted', true);
    return $button.trigger('click');
  }
};

MergeRequest.decreaseCounter = function (by = 1) {
  const $el = $('.js-merge-counter');
  const count = Math.max(parseInt($el.first().text().replace(/[^\d]/, ''), 10) - by, 0);

  $el.text(addDelimiter(count));
};

MergeRequest.toggleDraftStatus = function (title, isReady) {
  if (isReady) {
    toast(__('Marked as ready. Merging is now allowed.'));
  } else {
    toast(__('Marked as draft. Can only be merged when marked as ready.'));
  }
  const titleEl = document.querySelector(`.merge-request .detail-page-header .title`);

  if (titleEl) {
    titleEl.textContent = title;
  }

  const draftToggles = document.querySelectorAll('.js-draft-toggle-button');

  if (draftToggles.length) {
    draftToggles.forEach((el) => {
      const draftToggle = el;
      const url = setUrlParams(
        { 'merge_request[wip_event]': isReady ? 'draft' : 'ready' },
        draftToggle.href,
      );

      draftToggle.setAttribute('href', url);
      draftToggle.querySelector('.gl-dropdown-item-text-wrapper').textContent = isReady
        ? __('Mark as draft')
        : __('Mark as ready');
    });
  }
};

export default MergeRequest;
