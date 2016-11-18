/* eslint-disable */
(function() {
  (function(w) {
    var base;
    w.gl || (w.gl = {});
    (base = w.gl).utils || (base.utils = {});
    w.gl.utils.isInGroupsPage = function() {
      return gl.utils.getPagePath() === 'groups';
    };
    w.gl.utils.isInProjectPage = function() {
      return gl.utils.getPagePath() === 'projects';
    };
    w.gl.utils.getProjectSlug = function() {
      if (this.isInProjectPage()) {
        return $('body').data('project');
      } else {
        return null;
      }
    };
    w.gl.utils.getGroupSlug = function() {
      if (this.isInGroupsPage()) {
        return $('body').data('group');
      } else {
        return null;
      }
    };

    w.gl.utils.ajaxGet = function(url) {
      return $.ajax({
        type: "GET",
        url: url,
        dataType: "script"
      });
    };

    w.gl.utils.split = function(val) {
      return val.split(/,\s*/);
    };

    w.gl.utils.extractLast = function(term) {
      return this.split(term).pop();
    };

    w.gl.utils.rstrip = function rstrip(val) {
      if (val) {
        return val.replace(/\s+$/, '');
      } else {
        return val;
      }
    };

    w.gl.utils.disableButtonIfEmptyField = function(field_selector, button_selector, event_name) {
      event_name = event_name || 'input';
      var closest_submit, field, that;
      that = this;
      field = $(field_selector);
      closest_submit = field.closest('form').find(button_selector);
      if (this.rstrip(field.val()) === "") {
        closest_submit.disable();
      }
      return field.on(event_name, function() {
        if (that.rstrip($(this).val()) === "") {
          return closest_submit.disable();
        } else {
          return closest_submit.enable();
        }
      });
    };

    w.gl.utils.disableButtonIfAnyEmptyField = function(form, form_selector, button_selector) {
      var closest_submit, updateButtons;
      closest_submit = form.find(button_selector);
      updateButtons = function() {
        var filled;
        filled = true;
        form.find('input').filter(form_selector).each(function() {
          return filled = this.rstrip($(this).val()) !== "" || !$(this).attr('required');
        });
        if (filled) {
          return closest_submit.enable();
        } else {
          return closest_submit.disable();
        }
      };
      updateButtons();
      return form.keyup(updateButtons);
    };

    w.gl.utils.sanitize = function(str) {
      return str.replace(/<(?:.|\n)*?>/gm, '');
    };

    w.gl.utils.unbindEvents = function() {
      return $(document).off('scroll');
    };

    w.gl.utils.shiftWindow = function() {
      return w.scrollBy(0, -100);
    };


    gl.utils.updateTooltipTitle = function($tooltipEl, newTitle) {
      return $tooltipEl.tooltip('destroy').attr('title', newTitle).tooltip('fixTitle');
    };
    gl.utils.preventDisabledButtons = function() {
      return $('.btn').click(function(e) {
        if ($(this).hasClass('disabled')) {
          e.preventDefault();
          e.stopImmediatePropagation();
          return false;
        }
      });
    };
    gl.utils.getPagePath = function() {
      return $('body').data('page').split(':')[0];
    };
    gl.utils.parseUrl = function (url) {
      var parser = document.createElement('a');
      parser.href = url;
      return parser;
    };
    gl.utils.cleanupBeforeFetch = function() {
      // Unbind scroll events
      $(document).off('scroll');
      // Close any open tooltips
      $('.has-tooltip, [data-toggle="tooltip"]').tooltip('destroy');
    };

    gl.utils.isMetaKey = function(e) {
      return e.metaKey || e.ctrlKey || e.altKey || e.shiftKey;
    };

  })(window);

}).call(this);
