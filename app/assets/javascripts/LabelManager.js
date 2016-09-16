(function() {
  this.LabelManager = (function() {
    LabelManager.prototype.errorMessage = 'Unable to update label prioritization at this time';

    function LabelManager(opts) {
      // Defaults
      var ref, ref1, ref2, ref3, ref4;

      if (opts == null) {
        opts = {};
      }

      this.togglePriorityButton = (ref = opts.togglePriorityButton) != null ? ref : $('.js-toggle-priority');
      this.prioritizedLabels = (ref1 = opts.prioritizedLabels) != null ? ref1 : $('.js-prioritized-labels');
      this.globalLabels = (ref2 = opts.globalLabels) != null ? ref2 : $('.js-global-labels');
      this.groupLabels = (ref3 = opts.groupLabels) != null ? ref3 : $('.js-group-labels');
      this.projectLabels = (ref4 = opts.projectLabels) != null ? ref4 : $('.js-project-labels');

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
      // Make sure tooltip will hide
      $tooltip = $("#" + ($btn.find('.has-tooltip:visible').attr('aria-describedby')));
      $tooltip.tooltip('destroy');
      return _this.toggleLabelPriority($label, action);
    };

    LabelManager.prototype.toggleLabelPriority = function($label, action, persistState) {
      var $from, $target, $togglePriority, _this, url, type, xhr;

      if (persistState == null) {
        persistState = true;
      }

      _this = this;

      $togglePriority = $label.find('.js-toggle-priority');
      $labelType = $label.find('.js-label-type');
      url = $togglePriority.data('url');
      type = $togglePriority.data('type');

      $target = this.prioritizedLabels;
      $from = this.projectLabels;

      if (type === 'global_label') {
        $from = this.globalLabels;
      }

      if (type === 'group_label') {
        $from = this.groupLabels;
      }

      if (action === 'remove') {
        $from = [$target, $target = $from][0];
        $labelType.addClass('hidden');
      } else {
        $labelType.removeClass('hidden');
      }

      if ($from.children('li').length === 1) {
        $from.find('.empty-message').removeClass('hidden');
      }

      if (!$target.find('li').length) {
        $target.find('.empty-message').addClass('hidden');
      }

      $label.detach().appendTo($target);

      // Return if we are not persisting state
      if (!persistState) {
        return;
      }

      if (action === 'remove') {
        xhr = $.ajax({
          url: url,
          type: 'DELETE'
        });

        // Restore empty message
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

}).call(this);
