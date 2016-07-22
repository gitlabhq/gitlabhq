this.Compare = (function() {
  function Compare(opts) {
    this.opts = opts;
    this.source_loading = $(".js-source-loading");
    this.target_loading = $(".js-target-loading");
    $('.js-compare-dropdown').each((function(_this) {
      return function(i, dropdown) {
        var $dropdown;
        $dropdown = $(dropdown);
        return $dropdown.glDropdown({
          selectable: true,
          fieldName: $dropdown.data('field-name'),
          filterable: true,
          id: function(obj, $el) {
            return $el.data('id');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          },
          clicked: function(e, el) {
            if ($dropdown.is('.js-target-branch')) {
              return _this.getTargetHtml();
            } else if ($dropdown.is('.js-source-branch')) {
              return _this.getSourceHtml();
            } else if ($dropdown.is('.js-target-project')) {
              return _this.getTargetProject();
            }
          }
        });
      };
    })(this));
    this.initialState();
  }

  Compare.prototype.initialState = function() {
    this.getSourceHtml();
    return this.getTargetHtml();
  };

  Compare.prototype.getTargetProject = function() {
    return $.ajax({
      url: this.opts.targetProjectUrl,
      data: {
        target_project_id: $("input[name='merge_request[target_project_id]']").val()
      },
      beforeSend: function() {
        return $('.mr_target_commit').empty();
      },
      success: function(html) {
        return $('.js-target-branch-dropdown .dropdown-content').html(html);
      }
    });
  };

  Compare.prototype.getSourceHtml = function() {
    return this.sendAjax(this.opts.sourceBranchUrl, this.source_loading, '.mr_source_commit', {
      ref: $("input[name='merge_request[source_branch]']").val()
    });
  };

  Compare.prototype.getTargetHtml = function() {
    return this.sendAjax(this.opts.targetBranchUrl, this.target_loading, '.mr_target_commit', {
      target_project_id: $("input[name='merge_request[target_project_id]']").val(),
      ref: $("input[name='merge_request[target_branch]']").val()
    });
  };

  Compare.prototype.sendAjax = function(url, loading, target, data) {
    var $target;
    $target = $(target);
    return $.ajax({
      url: url,
      data: data,
      beforeSend: function() {
        loading.show();
        return $target.empty();
      },
      success: function(html) {
        loading.hide();
        $target.html(html);
        return $('.js-timeago', $target).timeago();
      }
    });
  };

  return Compare;

})();
