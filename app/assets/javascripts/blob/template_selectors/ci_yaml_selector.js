import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import FileTemplateSelector from '../file_template_selector';

export default class BlobCiYamlSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'gitlab-ci-yaml',
      name: '.gitlab-ci.yml',
      pattern: /(.gitlab-ci.yml)/,
      type: 'gitlab_ci_ymls',
      dropdown: '.js-gitlab-ci-yml-selector',
      wrapper: '.js-gitlab-ci-yml-selector-wrap',
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
      clicked: (options) => this.reportSelectionName(options),
      text: (item) => item.name,
    });
  }
}
