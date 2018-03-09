/* eslint-disable class-methods-use-this, no-new */

import $ from 'jquery';
import IssuableBulkUpdateActions from './issuable_bulk_update_actions';
import MilestoneSelect from './milestone_select';
import issueStatusSelect from './issue_status_select';
import subscriptionSelect from './subscription_select';
import LabelsSelect from './labels_select';

const HIDDEN_CLASS = 'hidden';
const DISABLED_CONTENT_CLASS = 'disabled-content';
const SIDEBAR_EXPANDED_CLASS = 'right-sidebar-expanded issuable-bulk-update-sidebar';
const SIDEBAR_COLLAPSED_CLASS = 'right-sidebar-collapsed issuable-bulk-update-sidebar';

export default class IssuableBulkUpdateSidebar {
  constructor() {
    this.initDomElements();
    this.bindEvents();
    this.initDropdowns();
    this.setupBulkUpdateActions();
  }

  initDomElements() {
    this.$page = $('.layout-page');
    this.$sidebar = $('.right-sidebar');
    this.$sidebarInnerContainer = this.$sidebar.find('.issuable-sidebar');
    this.$bulkEditCancelBtn = $('.js-bulk-update-menu-hide');
    this.$bulkEditSubmitBtn = $('.update-selected-issues');
    this.$bulkUpdateEnableBtn = $('.js-bulk-update-toggle');
    this.$otherFilters = $('.issues-other-filters');
    this.$checkAllContainer = $('.check-all-holder');
    this.$issueChecks = $('.issue-check');
    this.$issuesList = $('.selected_issue');
    this.$issuableIdsInput = $('#update_issuable_ids');
  }

  bindEvents() {
    this.$bulkUpdateEnableBtn.on('click', e => this.toggleBulkEdit(e, true));
    this.$bulkEditCancelBtn.on('click', e => this.toggleBulkEdit(e, false));
    this.$checkAllContainer.on('click', e => this.selectAll(e));
    this.$issuesList.on('change', () => this.updateFormState());
    this.$bulkEditSubmitBtn.on('click', () => this.prepForSubmit());
    this.$checkAllContainer.on('click', () => this.updateFormState());
  }

  initDropdowns() {
    new LabelsSelect();
    new MilestoneSelect();
    issueStatusSelect();
    subscriptionSelect();
  }

  setupBulkUpdateActions() {
    IssuableBulkUpdateActions.setOriginalDropdownData();
  }

  updateFormState() {
    const noCheckedIssues = !$('.selected_issue:checked').length;

    this.toggleSubmitButtonDisabled(noCheckedIssues);
    this.updateSelectedIssuableIds();

    IssuableBulkUpdateActions.setOriginalDropdownData();
  }

  prepForSubmit() {
    // if submit button is disabled, submission is blocked. This ensures we disable after
    // form submission is carried out
    setTimeout(() => this.$bulkEditSubmitBtn.disable());
    this.updateSelectedIssuableIds();
  }

  toggleBulkEdit(e, enable) {
    e.preventDefault();

    this.toggleSidebarDisplay(enable);
    this.toggleBulkEditButtonDisabled(enable);
    this.toggleOtherFiltersDisabled(enable);
    this.toggleCheckboxDisplay(enable);
  }

  updateSelectedIssuableIds() {
    this.$issuableIdsInput.val(IssuableBulkUpdateSidebar.getCheckedIssueIds());
  }

  selectAll() {
    const checkAllButtonState = this.$checkAllContainer.find('input').prop('checked');

    this.$issuesList.prop('checked', checkAllButtonState);
  }

  toggleSidebarDisplay(show) {
    this.$page.toggleClass(SIDEBAR_EXPANDED_CLASS, show);
    this.$page.toggleClass(SIDEBAR_COLLAPSED_CLASS, !show);
    this.$sidebarInnerContainer.toggleClass(HIDDEN_CLASS, !show);
    this.$sidebar.toggleClass(SIDEBAR_EXPANDED_CLASS, show);
    this.$sidebar.toggleClass(SIDEBAR_COLLAPSED_CLASS, !show);
  }

  toggleBulkEditButtonDisabled(disable) {
    if (disable) {
      this.$bulkUpdateEnableBtn.disable();
    } else {
      this.$bulkUpdateEnableBtn.enable();
    }
  }

  toggleCheckboxDisplay(show) {
    this.$checkAllContainer.toggleClass(HIDDEN_CLASS, !show);
    this.$issueChecks.toggleClass(HIDDEN_CLASS, !show);
  }

  toggleOtherFiltersDisabled(disable) {
    this.$otherFilters.toggleClass(DISABLED_CONTENT_CLASS, disable);
  }

  toggleSubmitButtonDisabled(disable) {
    if (disable) {
      this.$bulkEditSubmitBtn.disable();
    } else {
      this.$bulkEditSubmitBtn.enable();
    }
  }

  static getCheckedIssueIds() {
    const $checkedIssues = $('.selected_issue:checked');

    if ($checkedIssues.length > 0) {
      return $.map($checkedIssues, value => $(value).data('id'));
    }

    return [];
  }
}
