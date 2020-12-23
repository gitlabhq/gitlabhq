import FileTemplateSelector from '../file_template_selector';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default class BlobCiSyntaxYamlSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'gitlab-ci-yaml',
      name: '.gitlab-ci.yml',
      pattern: /(.gitlab-ci.yml)/,
      type: 'gitlab_ci_syntax_ymls',
      dropdown: '.js-gitlab-ci-syntax-yml-selector',
      wrapper: '.js-gitlab-ci-syntax-yml-selector-wrap',
    };
  }

  initDropdown() {
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
