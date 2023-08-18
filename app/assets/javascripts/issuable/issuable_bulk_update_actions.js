import $ from 'jquery';
import { difference, intersection, union } from 'lodash';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default {
  init({ form, issues, prefixId } = {}) {
    this.prefixId = prefixId || 'issue_';
    this.form = form || this.getElement('.bulk-update');
    this.$labelDropdown = this.form.find('.js-label-select');
    this.issues = issues || this.getElement('.issues-list .issue');
    this.willUpdateLabels = false;
    this.bindEvents();
  },

  bindEvents() {
    // eslint-disable-next-line @gitlab/no-global-event-off
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
    return createAlert({
      message: __('Issue update failed'),
    });
  },

  /**
   * Simple form serialization, it will return just what we need
   * Returns key/value pairs from form data
   */

  getFormDataAsObject() {
    const assigneeIds = this.form.find('input[name="update[assignee_ids][]"]').val();
    const formData = {
      update: {
        state_event: this.form.find('input[name="update[state_event]"]').val(),
        milestone_id: this.form.find('input[name="update[milestone_id]"]').val(),
        issuable_ids: this.form.find('input[name="update[issuable_ids]"]').val(),
        subscription_event: this.form.find('input[name="update[subscription_event]"]').val(),
        health_status: this.form.find('input[name="update[health_status]"]').val(),
        epic_id: this.form.find('input[name="update[epic_id]"]').val(),
        sprint_id: this.form.find('input[name="update[iteration_id]"]').val(),
        add_label_ids: [],
        remove_label_ids: [],
        confidential: this.form.find('input[name="update[confidentiality]"]').val(),
      },
    };
    if (assigneeIds) {
      formData.update.assignee_ids = [assigneeIds];
    }
    if (this.willUpdateLabels) {
      formData.update.add_label_ids = this.$labelDropdown.data('user-checked');
      formData.update.remove_label_ids = this.$labelDropdown.data('user-unchecked');
    }
    return formData;
  },

  setOriginalDropdownData() {
    const $labelSelect = $('.bulk-update .js-label-select');
    const userCheckedIds = $labelSelect.data('user-checked') || [];
    const userUncheckedIds = $labelSelect.data('user-unchecked') || [];

    // Common labels plus user checked labels minus user unchecked labels
    const checkedIdsToShow = difference(
      union(this.getOriginalCommonIds(), userCheckedIds),
      userUncheckedIds,
    );

    // Indeterminate labels minus user checked labels minus user unchecked labels
    const indeterminateIdsToShow = difference(
      this.getOriginalIndeterminateIds(),
      userCheckedIds,
      userUncheckedIds,
    );

    $labelSelect.data('marked', checkedIdsToShow);
    $labelSelect.data('indeterminate', indeterminateIdsToShow);
  },

  // From issuable's initial bulk selection
  getOriginalCommonIds() {
    const labelIds = [];
    this.getElement('.issuable-list input[type="checkbox"]:checked').each((i, el) => {
      labelIds.push(this.getElement(`#${this.prefixId}${el.dataset.id}`).data('labels'));
    });
    return intersection.apply(this, labelIds);
  },

  // From issuable's initial bulk selection
  getOriginalIndeterminateIds() {
    const uniqueIds = [];
    const labelIds = [];
    let issuableLabels = [];

    // Collect unique label IDs for all checked issues
    this.getElement('.issuable-list input[type="checkbox"]:checked').each((i, el) => {
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
    // Return IDs that are present but not in all selected issuables
    return uniqueIds.filter((x) => !intersection.apply(this, labelIds).includes(x));
  },

  getElement(selector) {
    this.scopeEl = this.scopeEl || $('.content');
    return this.scopeEl.find(selector);
  },
};
