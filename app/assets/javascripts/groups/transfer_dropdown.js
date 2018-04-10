import $ from 'jquery';

export default class TransferDropdown {
  constructor() {
    this.groupDropdown = $('.js-groups-dropdown');
    this.parentInput = $('#new_parent_group_id');
    this.data = this.groupDropdown.data('data');
    this.init();
  }

  init() {
    this.buildDropdown();
  }

  buildDropdown() {
    const extraOptions = [{ id: '', text: 'No parent group' }, 'divider'];

    this.groupDropdown.glDropdown({
      selectable: true,
      filterable: true,
      toggleLabel: item => item.text,
      search: { fields: ['text'] },
      data: extraOptions.concat(this.data),
      text: item => item.text,
      clicked: (options) => {
        const { e } = options;
        e.preventDefault();
        this.assignSelected(options.selectedObj);
      },
    });
  }

  assignSelected(selected) {
    this.parentInput.val(selected.id);
  }
}
