this.IssuableBulkActions = (function() {
  function IssuableBulkActions(opts) {
    var ref, ref1, ref2;
    if (opts == null) {
      opts = {};
    }
    this.container = (ref = opts.container) != null ? ref : $('.content'), this.form = (ref1 = opts.form) != null ? ref1 : this.getElement('.bulk-update'), this.issues = (ref2 = opts.issues) != null ? ref2 : this.getElement('.issues-list .issue');
    this.form.data('bulkActions', this);
    this.willUpdateLabels = false;
    this.bindEvents();
    Issuable.initChecks();
  }

  IssuableBulkActions.prototype.getElement = function(selector) {
    return this.container.find(selector);
  };

  IssuableBulkActions.prototype.bindEvents = function() {
    return this.form.off('submit').on('submit', this.onFormSubmit.bind(this));
  };

  IssuableBulkActions.prototype.onFormSubmit = function(e) {
    e.preventDefault();
    return this.submit();
  };

  IssuableBulkActions.prototype.submit = function() {
    var _this, xhr;
    _this = this;
    xhr = $.ajax({
      url: this.form.attr('action'),
      method: this.form.attr('method'),
      dataType: 'JSON',
      data: this.getFormDataAsObject()
    });
    xhr.done(function(response, status, xhr) {
      return location.reload();
    });
    xhr.fail(function() {
      return new Flash("Issue update failed");
    });
    return xhr.always(this.onFormSubmitAlways.bind(this));
  };

  IssuableBulkActions.prototype.onFormSubmitAlways = function() {
    return this.form.find('[type="submit"]').enable();
  };

  IssuableBulkActions.prototype.getSelectedIssues = function() {
    return this.issues.has('.selected_issue:checked');
  };

  IssuableBulkActions.prototype.getLabelsFromSelection = function() {
    var labels;
    labels = [];
    this.getSelectedIssues().map(function() {
      var _labels;
      _labels = $(this).data('labels');
      if (_labels) {
        return _labels.map(function(labelId) {
          if (labels.indexOf(labelId) === -1) {
            return labels.push(labelId);
          }
        });
      }
    });
    return labels;
  };


  /**
   * Will return only labels that were marked previously and the user has unmarked
   * @return {Array} Label IDs
   */

  IssuableBulkActions.prototype.getUnmarkedIndeterminedLabels = function() {
    var el, i, id, j, labelsToKeep, len, len1, ref, ref1, result;
    result = [];
    labelsToKeep = [];
    ref = this.getElement('.labels-filter .is-indeterminate');
    for (i = 0, len = ref.length; i < len; i++) {
      el = ref[i];
      labelsToKeep.push($(el).data('labelId'));
    }
    ref1 = this.getLabelsFromSelection();
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      id = ref1[j];
      if (labelsToKeep.indexOf(id) === -1) {
        result.push(id);
      }
    }
    return result;
  };


  /**
   * Simple form serialization, it will return just what we need
   * Returns key/value pairs from form data
   */

  IssuableBulkActions.prototype.getFormDataAsObject = function() {
    var formData;
    formData = {
      update: {
        state_event: this.form.find('input[name="update[state_event]"]').val(),
        assignee_id: this.form.find('input[name="update[assignee_id]"]').val(),
        milestone_id: this.form.find('input[name="update[milestone_id]"]').val(),
        issues_ids: this.form.find('input[name="update[issues_ids]"]').val(),
        subscription_event: this.form.find('input[name="update[subscription_event]"]').val(),
        add_label_ids: [],
        remove_label_ids: []
      }
    };
    if (this.willUpdateLabels) {
      this.getLabelsToApply().map(function(id) {
        return formData.update.add_label_ids.push(id);
      });
      this.getLabelsToRemove().map(function(id) {
        return formData.update.remove_label_ids.push(id);
      });
    }
    return formData;
  };

  IssuableBulkActions.prototype.getLabelsToApply = function() {
    var $labels, labelIds;
    labelIds = [];
    $labels = this.form.find('.labels-filter input[name="update[label_ids][]"]');
    $labels.each(function(k, label) {
      if (label) {
        return labelIds.push(parseInt($(label).val()));
      }
    });
    return labelIds;
  };


  /**
   * Returns Label IDs that will be removed from issue selection
   * @return {Array} Array of labels IDs
   */

  IssuableBulkActions.prototype.getLabelsToRemove = function() {
    var indeterminatedLabels, labelsToApply, result;
    result = [];
    indeterminatedLabels = this.getUnmarkedIndeterminedLabels();
    labelsToApply = this.getLabelsToApply();
    indeterminatedLabels.map(function(id) {
      if (labelsToApply.indexOf(id) === -1) {
        return result.push(id);
      }
    });
    return result;
  };

  return IssuableBulkActions;

})();
