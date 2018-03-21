/* eslint-disable comma-dangle, quotes, consistent-return, func-names, array-callback-return, space-before-function-paren, prefer-arrow-callback, max-len, no-unused-expressions, no-sequences, no-underscore-dangle, no-unused-vars, no-param-reassign */

import $ from 'jquery';
import _ from 'underscore';
import axios from './lib/utils/axios_utils';
import Flash from './flash';

export default {
  init({ container, form, issues, prefixId } = {}) {
    this.prefixId = prefixId || 'issue_';
    this.form = form || this.getElement('.bulk-update');
    this.$labelDropdown = this.form.find('.js-label-select');
    this.issues = issues || this.getElement('.issues-list .issue');
    this.willUpdateLabels = false;
    this.bindEvents();
  },

  bindEvents() {
    return this.form.off('submit').on('submit', this.onFormSubmit.bind(this));
  },

  onFormSubmit(e) {
    e.preventDefault();
    return this.submit();
  },

  submit() {
    axios[this.form.attr('method')](this.form.attr('action'), this.getFormDataAsObject())
      .then(() => window.location.reload())
      .catch(() => this.onFormSubmitFailure());
  },

  onFormSubmitFailure() {
    this.form.find('[type="submit"]').enable();
    return new Flash("Issue update failed");
  },

  getSelectedIssues() {
    return this.issues.has('.selected_issue:checked');
  },

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
  },

  /**
   * Will return only labels that were marked previously and the user has unmarked
   * @return {Array} Label IDs
   */

  getUnmarkedIndeterminedLabels() {
    const result = [];
    const labelsToKeep = this.$labelDropdown.data('indeterminate');

    this.getLabelsFromSelection().forEach((id) => {
      if (labelsToKeep.indexOf(id) === -1) {
        result.push(id);
      }
    });

    return result;
  },

  /**
   * Simple form serialization, it will return just what we need
   * Returns key/value pairs from form data
   */

  getFormDataAsObject() {
    const formData = {
      update: {
        state_event: this.form.find('input[name="update[state_event]"]').val(),
        // For Merge Requests
        assignee_id: this.form.find('input[name="update[assignee_id]"]').val(),
        // For Issues
        assignee_ids: [this.form.find('input[name="update[assignee_ids][]"]').val()],
        milestone_id: this.form.find('input[name="update[milestone_id]"]').val(),
        issuable_ids: this.form.find('input[name="update[issuable_ids]"]').val(),
        subscription_event: this.form.find('input[name="update[subscription_event]"]').val(),
        add_label_ids: [],
        remove_label_ids: []
      }
    };
    if (this.willUpdateLabels) {
      formData.update.add_label_ids = this.$labelDropdown.data('marked');
      formData.update.remove_label_ids = this.$labelDropdown.data('unmarked');
    }
    return formData;
  },

  setOriginalDropdownData() {
    const $labelSelect = $('.bulk-update .js-label-select');
    $labelSelect.data('common', this.getOriginalCommonIds());
    $labelSelect.data('marked', this.getOriginalMarkedIds());
    $labelSelect.data('indeterminate', this.getOriginalIndeterminateIds());
  },

  // From issuable's initial bulk selection
  getOriginalCommonIds() {
    const labelIds = [];

    this.getElement('.selected_issue:checked').each((i, el) => {
      labelIds.push(this.getElement(`#${this.prefixId}${el.dataset.id}`).data('labels'));
    });
    return _.intersection.apply(this, labelIds);
  },

  // From issuable's initial bulk selection
  getOriginalMarkedIds() {
    const labelIds = [];
    this.getElement('.selected_issue:checked').each((i, el) => {
      labelIds.push(this.getElement(`#${this.prefixId}${el.dataset.id}`).data('labels'));
    });
    return _.intersection.apply(this, labelIds);
  },

  // From issuable's initial bulk selection
  getOriginalIndeterminateIds() {
    const uniqueIds = [];
    const labelIds = [];
    let issuableLabels = [];

    // Collect unique label IDs for all checked issues
    this.getElement('.selected_issue:checked').each((i, el) => {
      issuableLabels = this.getElement(`#${this.prefixId}${el.dataset.id}`).data('labels');
      issuableLabels.forEach((labelId) => {
        // Store unique IDs
        if (uniqueIds.indexOf(labelId) === -1) {
          uniqueIds.push(labelId);
        }
      });
      // Store array of IDs per issuable
      labelIds.push(issuableLabels);
    });
    // Add uniqueIds to add it as argument for _.intersection
    labelIds.unshift(uniqueIds);
    // Return IDs that are present but not in all selected issueables
    return _.difference(uniqueIds, _.intersection.apply(this, labelIds));
  },

  getElement(selector) {
    this.scopeEl = this.scopeEl || $('.content');
    return this.scopeEl.find(selector);
  },
};
