import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
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
    initDeprecatedJQueryDropdown(this.$dropdown, {
      data: this.config.dropdownData,
      filterable: false,
      selectable: true,
      clicked: (options) => this.mediator.selectTemplateTypeOptions(options),
      text: (item) => item.name,
    });
  }
}
