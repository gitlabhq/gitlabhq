/* eslint-disable */
((global) => {

  class IssuableBulkActions {
    constructor({ container, form, issues } = {}) {
      this.container = container || $('.content'),
      this.form = form || this.getElement('.bulk-update');
      this.issues = issues || this.getElement('.issues-list .issue');
      this.form.data('bulkActions', this);
      this.willUpdateLabels = false;
      this.bindEvents();
      // Fixes bulk-assign not working when navigating through pages
      Issuable.initChecks();
    }

    getElement(selector) {
      return this.container.find(selector);
    }

    bindEvents() {
      return this.form.off('submit').on('submit', this.onFormSubmit.bind(this));
    }

    onFormSubmit(e) {
      e.preventDefault();
      return this.submit();
    }

    submit() {
      const _this = this;
      const xhr = $.ajax({
        url: this.form.attr('action'),
        method: this.form.attr('method'),
        dataType: 'JSON',
        data: this.getFormDataAsObject()
      });
      xhr.done(() => window.location.reload());
      xhr.fail(() => new Flash("Issue update failed"));
      return xhr.always(this.onFormSubmitAlways.bind(this));
    }

    onFormSubmitAlways() {
      return this.form.find('[type="submit"]').enable();
    }

    getSelectedIssues() {
      return this.issues.has('.selected_issue:checked');
    }

    getLabelsFromSelection() {
      const labels = [];
      this.getSelectedIssues().map(function() {
        const labelsData = $(this).data('labels');
        if (labelsData) {
          return labelsData.map(function(labelId) {
            if (labels.indexOf(labelId) === -1) {
              return labels.push(labelId);
            }
          });
        }
      });
      return labels;
    }


    /**
     * Will return only labels that were marked previously and the user has unmarked
     * @return {Array} Label IDs
     */

    getUnmarkedIndeterminedLabels() {
      const result = [];
      const labelsToKeep = [];

      this.getElement('.labels-filter .is-indeterminate')
        .each((i, el) => labelsToKeep.push($(el).data('labelId')));

      this.getLabelsFromSelection().forEach((id) => {
        if (labelsToKeep.indexOf(id) === -1) {
          result.push(id);
        }
      });

      return result;
    }


    /**
     * Simple form serialization, it will return just what we need
     * Returns key/value pairs from form data
     */

    getFormDataAsObject() {
      const formData = {
        update: {
          state_event: this.form.find('input[name="update[state_event]"]').val(),
          assignee_id: this.form.find('input[name="update[assignee_id]"]').val(),
          milestone_id: this.form.find('input[name="update[milestone_id]"]').val(),
          issuable_ids: this.form.find('input[name="update[issuable_ids]"]').val(),
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
    }

    getLabelsToApply() {
      const labelIds = [];
      const $labels = this.form.find('.labels-filter input[name="update[label_ids][]"]');
      $labels.each(function(k, label) {
        if (label) {
          return labelIds.push(parseInt($(label).val()));
        }
      });
      return labelIds;
    }


    /**
     * Returns Label IDs that will be removed from issue selection
     * @return {Array} Array of labels IDs
     */

    getLabelsToRemove() {
      const result = [];
      const indeterminatedLabels = this.getUnmarkedIndeterminedLabels();
      const labelsToApply = this.getLabelsToApply();
      indeterminatedLabels.map(function(id) {
        // We need to exclude label IDs that will be applied
        // By not doing this will cause issues from selection to not add labels at all
        if (labelsToApply.indexOf(id) === -1) {
          return result.push(id);
        }
      });
      return result;
    }
  }

  global.IssuableBulkActions = IssuableBulkActions;

})(window.gl || (window.gl = {}));
