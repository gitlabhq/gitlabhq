import FileTemplateSelector from '../file_template_selector';

export default class BlobLicenseSelector extends FileTemplateSelector {
  constructor({ mediator }) {
    super(mediator);
    this.config = {
      key: 'license',
      name: 'LICENSE',
      pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
      type: 'licenses',
      dropdown: '.js-license-selector',
      wrapper: '.js-license-selector-wrap',
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
      clicked: options => {
        const { e } = options;
        const el = options.$el;
        const query = options.selectedObj;

        const data = {
          project: this.$dropdown.data('project'),
          fullname: this.$dropdown.data('fullname'),
        };

        this.reportSelection({
          query: query.id,
          el,
          e,
          data,
        });
      },
      text: item => item.name,
    });
  }
}
