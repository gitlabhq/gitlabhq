import FileTemplateSelector from '../file_template_selector';
import { __ } from '~/locale';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default class DockerfileSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'dockerfile',
      name: __('Dockerfile'),
      pattern: /(Dockerfile)/,
      type: 'dockerfiles',
      dropdown: '.js-dockerfile-selector',
      wrapper: '.js-dockerfile-selector-wrap',
    };
  }

  initDropdown() {
    // maybe move to super class as well
    initDeprecatedJQueryDropdown(this.$dropdown, {
      data: this.$dropdown.data('data'),
      filterable: true,
      selectable: true,
      search: {
        fields: ['name'],
      },
      clicked: options => this.reportSelectionName(options),
      text: item => item.name,
    });
  }
}
