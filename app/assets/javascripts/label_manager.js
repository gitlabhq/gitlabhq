/* eslint-disable comma-dangle, class-methods-use-this, no-underscore-dangle, no-param-reassign, no-unused-vars, consistent-return, func-names, space-before-function-paren, max-len */

import $ from 'jquery';
import Sortable from 'vendor/Sortable';

import flash from './flash';
import axios from './lib/utils/axios_utils';

export default class LabelManager {
  constructor({ togglePriorityButton, prioritizedLabels, otherLabels } = {}) {
    this.togglePriorityButton = togglePriorityButton || $('.js-toggle-priority');
    this.prioritizedLabels = prioritizedLabels || $('.js-prioritized-labels');
    this.otherLabels = otherLabels || $('.js-other-labels');
    this.errorMessage = 'Unable to update label prioritization at this time';
    this.emptyState = document.querySelector('#js-priority-labels-empty-state');
    this.sortable = Sortable.create(this.prioritizedLabels.get(0), {
      filter: '.empty-message',
      forceFallback: true,
      fallbackClass: 'is-dragging',
      dataIdAttr: 'data-id',
      onUpdate: this.onPrioritySortUpdate.bind(this),
    });
    this.bindEvents();
  }

  bindEvents() {
    this.prioritizedLabels.find('.btn-action').on('mousedown', this, this.onButtonActionClick);
    return this.togglePriorityButton.on('click', this, this.onTogglePriorityClick);
  }

  onTogglePriorityClick(e) {
    e.preventDefault();
    const _this = e.data;
    const $btn = $(e.currentTarget);
    const $label = $(`#${$btn.data('domId')}`);
    const action = $btn.parents('.js-prioritized-labels').length ? 'remove' : 'add';
    const $tooltip = $(`#${$btn.find('.has-tooltip:visible').attr('aria-describedby')}`);
    $tooltip.tooltip('destroy');
    _this.toggleLabelPriority($label, action);
    _this.toggleEmptyState($label, $btn, action);
  }

  onButtonActionClick(e) {
    e.stopPropagation();
    $(e.currentTarget).tooltip('hide');
  }

  toggleEmptyState($label, $btn, action) {
    this.emptyState.classList.toggle('hidden', !!this.prioritizedLabels[0].querySelector(':scope > li'));
  }

  toggleLabelPriority($label, action, persistState) {
    if (persistState == null) {
      persistState = true;
    }
    const _this = this;
    const url = $label.find('.js-toggle-priority').data('url');
    let $target = this.prioritizedLabels;
    let $from = this.otherLabels;
    const rollbackLabelPosition = this.rollbackLabelPosition.bind(this, $label, action);

    if (action === 'remove') {
      $target = this.otherLabels;
      $from = this.prioritizedLabels;
    }
    $label.detach().appendTo($target);
    if ($from.find('li').length) {
      $from.find('.empty-message').removeClass('hidden');
    }
    if ($target.find('> li:not(.empty-message)').length) {
      $target.find('.empty-message').addClass('hidden');
    }
    // Return if we are not persisting state
    if (!persistState) {
      return;
    }
    if (action === 'remove') {
      axios.delete(url)
        .catch(rollbackLabelPosition);

      // Restore empty message
      if (!$from.find('li').length) {
        $from.find('.empty-message').removeClass('hidden');
      }
    } else {
      this.savePrioritySort($label, action)
        .catch(rollbackLabelPosition);
    }
  }

  onPrioritySortUpdate() {
    this.savePrioritySort()
      .catch(() => flash(this.errorMessage));
  }

  savePrioritySort() {
    return axios.post(this.prioritizedLabels.data('url'), {
      label_ids: this.getSortedLabelsIds(),
    });
  }

  rollbackLabelPosition($label, originalAction) {
    const action = originalAction === 'remove' ? 'add' : 'remove';
    this.toggleLabelPriority($label, action, false);
    flash(this.errorMessage);
  }

  getSortedLabelsIds() {
    const sortedIds = [];
    this.prioritizedLabels.find('> li').each(function() {
      const id = $(this).data('id');

      if (id) {
        sortedIds.push(id);
      }
    });
    return sortedIds;
  }
}
