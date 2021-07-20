/* eslint-disable  class-methods-use-this, no-underscore-dangle, no-param-reassign, func-names */

import $ from 'jquery';
import Sortable from 'sortablejs';
import { dispose } from '~/tooltips';
import createFlash from './flash';
import axios from './lib/utils/axios_utils';
import { __ } from './locale';

export default class LabelManager {
  constructor({ togglePriorityButton, prioritizedLabels, otherLabels } = {}) {
    this.togglePriorityButton = togglePriorityButton || $('.js-toggle-priority');
    this.prioritizedLabels = prioritizedLabels || $('.js-prioritized-labels');
    this.otherLabels = otherLabels || $('.js-other-labels');
    this.errorMessage = __('Unable to update label prioritization at this time');
    this.emptyState = document.querySelector('#js-priority-labels-empty-state');
    this.$badgeItemTemplate = $('#js-badge-item-template');

    if ('sortable' in this.prioritizedLabels.data()) {
      Sortable.create(this.prioritizedLabels.get(0), {
        filter: '.empty-message',
        forceFallback: true,
        fallbackClass: 'is-dragging',
        dataIdAttr: 'data-id',
        onUpdate: this.onPrioritySortUpdate.bind(this),
      });
    }
    this.bindEvents();
  }

  bindEvents() {
    return this.togglePriorityButton.on('click', this, this.onTogglePriorityClick);
  }

  onTogglePriorityClick(e) {
    e.preventDefault();
    const _this = e.data;
    const $btn = $(e.currentTarget);
    const $label = $(`#${$btn.data('domId')}`);
    const action = $btn.parents('.js-prioritized-labels').length ? 'remove' : 'add';
    const $tooltip = $(`#${$btn.find('.has-tooltip:visible').attr('aria-describedby')}`);
    dispose($tooltip);
    _this.toggleLabelPriority($label, action);
    _this.toggleEmptyState($label, $btn, action);
  }

  toggleEmptyState() {
    this.emptyState.classList.toggle(
      'hidden',
      Boolean(this.prioritizedLabels[0].querySelector(':scope > li')),
    );
  }

  toggleLabelPriority($label, action, persistState) {
    if (persistState == null) {
      persistState = true;
    }
    const url = $label.find('.js-toggle-priority').data('url');
    let $target = this.prioritizedLabels;
    let $from = this.otherLabels;
    const rollbackLabelPosition = this.rollbackLabelPosition.bind(this, $label, action);

    if (action === 'remove') {
      $target = this.otherLabels;
      $from = this.prioritizedLabels;
    }

    const $detachedLabel = $label.detach();
    this.toggleLabelPriorityBadge($detachedLabel, action);

    const $labelEls = $target.find('li.label-list-item');

    /*
     * If there is a label element in the target, we'd want to
     * append the new label just right next to it.
     */
    if ($labelEls.length) {
      $labelEls.last().after($detachedLabel);
    } else {
      $detachedLabel.appendTo($target);
    }

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
      axios.delete(url).catch(rollbackLabelPosition);

      // Restore empty message
      if (!$from.find('li').length) {
        $from.find('.empty-message').removeClass('hidden');
      }
    } else {
      this.savePrioritySort($label, action).catch(rollbackLabelPosition);
    }
  }

  toggleLabelPriorityBadge($label, action) {
    if (action === 'remove') {
      $('.js-priority-badge', $label).remove();
    } else {
      $('.label-links', $label).append(this.$badgeItemTemplate.clone().html());
    }
  }

  onPrioritySortUpdate() {
    this.savePrioritySort().catch(() =>
      createFlash({
        message: this.errorMessage,
      }),
    );
  }

  savePrioritySort() {
    return axios.post(this.prioritizedLabels.data('url'), {
      label_ids: this.getSortedLabelsIds(),
    });
  }

  rollbackLabelPosition($label, originalAction) {
    const action = originalAction === 'remove' ? 'add' : 'remove';
    this.toggleLabelPriority($label, action, false);
    createFlash({
      message: this.errorMessage,
    });
  }

  getSortedLabelsIds() {
    const sortedIds = [];
    this.prioritizedLabels.find('> li').each(function () {
      const id = $(this).data('id');

      if (id) {
        sortedIds.push(id);
      }
    });
    return sortedIds;
  }
}
