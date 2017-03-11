/* global Api */

import TemplateSelector from './template_selector';

export default class BlobLicenseSelector extends TemplateSelector {
  requestFile(query) {
    const project = this.dropdown.data('project');
    const fullname = this.dropdown.data('fullname');
    return Api.licenseText(query.id, { project, fullname }, this.requestFileSuccess.bind(this));
  }
}
