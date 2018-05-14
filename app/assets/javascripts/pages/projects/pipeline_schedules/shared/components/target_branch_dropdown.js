import $ from 'jquery';

export default class TargetBranchDropdown {
  constructor() {
    this.$dropdown = $('.js-target-branch-dropdown');
    this.$dropdownToggle = this.$dropdown.find('.dropdown-toggle-text');
    this.$input = $('#schedule_ref');
    this.initDefaultBranch();
    this.initDropdown();
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.formatBranchesList(),
      filterable: true,
      selectable: true,
      toggleLabel: item => item.name,
      search: {
        fields: ['name'],
      },
      clicked: cfg => this.updateInputValue(cfg),
      text: item => item.name,
    });

    this.setDropdownToggle();
  }

  formatBranchesList() {
    return this.$dropdown.data('data')
      .map(val => ({ name: val }));
  }

  setDropdownToggle() {
    const initialValue = this.$input.val();

    this.$dropdownToggle.text(initialValue);
  }

  initDefaultBranch() {
    const initialValue = this.$input.val();
    const defaultBranch = this.$dropdown.data('defaultBranch');

    if (!initialValue) {
      this.$input.val(defaultBranch);
    }
  }

  updateInputValue({ selectedObj, e }) {
    e.preventDefault();

    this.$input.val(selectedObj.name);
    gl.pipelineScheduleFieldErrors.updateFormValidityState();
  }
}
