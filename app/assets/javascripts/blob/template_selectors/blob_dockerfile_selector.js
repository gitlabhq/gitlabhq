/* global Api */

import TemplateSelector from './template_selector';

export default class BlobDockerfileSelector extends TemplateSelector {
  requestFile(query) {
    return Api.dockerfileYml(query.name, (file, config) => this.setEditorContent(file, config));
  }
}
