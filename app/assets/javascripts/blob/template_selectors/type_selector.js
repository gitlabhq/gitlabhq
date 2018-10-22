import FileTemplateSelector from '../file_template_selector';

export default class FileTemplateTypeSelector extends FileTemplateSelector {
  constructor({ mediator, dropdownData }) {
    super(mediator);
    this.mediator = mediator;
    this.config = {
      dropdown: '.js-template-type-selector',
      wrapper: '.js-template-type-selector-wrap',
      dropdownData,
    };
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.config.dropdownData,
      filterable: false,
      selectable: true,
      toggleLabel: item => item.name,
      clicked: options => this.mediator.selectTemplateTypeOptions(options),
      text: item => item.name,
    });
  }
}
