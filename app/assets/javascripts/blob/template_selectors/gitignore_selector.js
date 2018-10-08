import FileTemplateSelector from '../file_template_selector';

export default class BlobGitignoreSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'gitignore',
      name: '.gitignore',
      pattern: /(.gitignore)/,
      type: 'gitignores',
      dropdown: '.js-gitignore-selector',
      wrapper: '.js-gitignore-selector-wrap',
    };
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.$dropdown.data('data'),
      filterable: true,
      selectable: true,
      toggleLabel: item => item.name,
      search: {
        fields: ['name'],
      },
      clicked: options => this.reportSelectionName(options),
      text: item => item.name,
    });
  }
}
