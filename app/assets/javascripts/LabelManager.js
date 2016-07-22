this.LabelManager = (function() {
  LabelManager.prototype.errorMessage = 'Unable to update label prioritization at this time';

  function LabelManager(opts) {
    var ref, ref1, ref2;
    if (opts == null) {
      opts = {};
    }
    this.togglePriorityButton = (ref = opts.togglePriorityButton) != null ? ref : $('.js-toggle-priority'), this.prioritizedLabels = (ref1 = opts.prioritizedLabels) != null ? ref1 : $('.js-prioritized-labels'), this.otherLabels = (ref2 = opts.otherLabels) != null ? ref2 : $('.js-other-labels');
    this.prioritizedLabels.sortable({
      items: 'li',
      placeholder: 'list-placeholder',
      axis: 'y',
      update: this.onPrioritySortUpdate.bind(this)
    });
    this.bindEvents();
  }

  LabelManager.prototype.bindEvents = function() {
    return this.togglePriorityButton.on('click', this, this.onTogglePriorityClick);
  };

  LabelManager.prototype.onTogglePriorityClick = function(e) {
    var $btn, $label, $tooltip, _this, action;
    e.preventDefault();
    _this = e.data;
    $btn = $(e.currentTarget);
    $label = $("#" + ($btn.data('domId')));
    action = $btn.parents('.js-prioritized-labels').length ? 'remove' : 'add';
    $tooltip = $("#" + ($btn.find('.has-tooltip:visible').attr('aria-describedby')));
    $tooltip.tooltip('destroy');
    return _this.toggleLabelPriority($label, action);
  };

  LabelManager.prototype.toggleLabelPriority = function($label, action, persistState) {
    var $from, $target, _this, url, xhr;
    if (persistState == null) {
      persistState = true;
    }
    _this = this;
    url = $label.find('.js-toggle-priority').data('url');
    $target = this.prioritizedLabels;
    $from = this.otherLabels;
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
        url: url,
        type: 'DELETE'
      });
      if (!$from.find('li').length) {
        $from.find('.empty-message').removeClass('hidden');
      }
    } else {
      xhr = this.savePrioritySort($label, action);
    }
    return xhr.fail(this.rollbackLabelPosition.bind(this, $label, action));
  };

  LabelManager.prototype.onPrioritySortUpdate = function() {
    var xhr;
    xhr = this.savePrioritySort();
    return xhr.fail(function() {
      return new Flash(this.errorMessage, 'alert');
    });
  };

  LabelManager.prototype.savePrioritySort = function() {
    return $.post({
      url: this.prioritizedLabels.data('url'),
      data: {
        label_ids: this.getSortedLabelsIds()
      }
    });
  };

  LabelManager.prototype.rollbackLabelPosition = function($label, originalAction) {
    var action;
    action = originalAction === 'remove' ? 'add' : 'remove';
    this.toggleLabelPriority($label, action, false);
    return new Flash(this.errorMessage, 'alert');
  };

  LabelManager.prototype.getSortedLabelsIds = function() {
    var sortedIds;
    sortedIds = [];
    this.prioritizedLabels.find('li').each(function() {
      return sortedIds.push($(this).data('id'));
    });
    return sortedIds;
  };

  return LabelManager;

})();
