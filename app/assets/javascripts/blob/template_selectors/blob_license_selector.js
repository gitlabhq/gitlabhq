/* global Api */

import TemplateSelector from './template_selector';

export default class BlobLicenseSelector extends TemplateSelector {
  requestFile(query) {
    const data = {
      project: this.dropdown.data('project'),
      fullname: this.dropdown.data('fullname'),
    };
    return Api.licenseText(query.id, data, (file, config) => this.setEditorContent(file, config));
  }
}
