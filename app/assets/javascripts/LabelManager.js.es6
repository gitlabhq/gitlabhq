((global) => {

  class LabelManager {
    constructor({ togglePriorityButton, prioritizedLabels, otherLabels } = {}) {
      this.togglePriorityButton = togglePriorityButton || $('.js-toggle-priority');
      this.prioritizedLabels = prioritizedLabels || $('.js-prioritized-labels');
      this.otherLabels = otherLabels || $('.js-other-labels');
      this.errorMessage = 'Unable to update label prioritization at this time';
      this.prioritizedLabels.sortable({
        items: 'li',
        placeholder: 'list-placeholder',
        axis: 'y',
        update: this.onPrioritySortUpdate.bind(this)
      });
      this.bindEvents();
    }

    bindEvents() {
      // TODO: Check if this is being bound correctly
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
      return _this.toggleLabelPriority($label, action);
    }

    toggleLabelPriority($label, action, persistState) {
      if (persistState == null) {
        persistState = true;
      }
      let xhr;
      const _this = this;
      const url = $label.find('.js-toggle-priority').data('url');
      let $target = this.prioritizedLabels;
      let $from = this.otherLabels;
      if (action === 'remove') {
        $target = this.otherLabels;
        $from = this.prioritizedLabels;
      }
      if ($from.find('li').length === 1) {
        $from.find('.empty-message').removeClass('hidden');
      }
      if (!$target.find('li').length) {
        $target.find('.empty-message').addClass('hidden');
      }
      $label.detach().appendTo($target);
      if (!persistState) {
        return;
      }
      if (action === 'remove') {
        xhr = $.ajax({
          url,
          type: 'DELETE'
        });
        if (!$from.find('li').length) {
          $from.find('.empty-message').removeClass('hidden');
        }
      } else {
        xhr = this.savePrioritySort($label, action);
      }
      return xhr.fail(this.rollbackLabelPosition.bind(this, $label, action));
    }

    onPrioritySortUpdate() {
      const xhr = this.savePrioritySort();
      return xhr.fail(function() {
        return new Flash(this.errorMessage, 'alert');
      });
    }

    savePrioritySort() {
      return $.post({
        url: this.prioritizedLabels.data('url'),
        data: {
          label_ids: this.getSortedLabelsIds()
        }
      });
    }

    rollbackLabelPosition($label, originalAction) {
      const action = originalAction === 'remove' ? 'add' : 'remove';
      this.toggleLabelPriority($label, action, false);
      return new Flash(this.errorMessage, 'alert');
    }

    getSortedLabelsIds() {
      const sortedIds = [];
      this.prioritizedLabels.find('li').each(function() {
        sortedIds.push($(this).data('id'));
      });
      return sortedIds;
    }
  }

  gl.LabelManager = LabelManager;

})(window.gl || (window.gl = {}));

