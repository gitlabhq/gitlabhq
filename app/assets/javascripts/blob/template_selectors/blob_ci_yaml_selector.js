/* global Api */

import TemplateSelector from './template_selector';

export default class BlobCiYamlSelector extends TemplateSelector {
  requestFile(query) {
    return Api.gitlabCiYml(query.name, (file, config) => this.setEditorContent(file, config));
  }
}
