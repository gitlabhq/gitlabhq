/* global Api */

import TemplateSelector from './template_selector';

export default class BlobDockerfileSelector extends TemplateSelector {
  requestFile(query) {
    return Api.dockerfileYml(query.name, this.requestFileSuccess.bind(this));
  }

  requestFileSuccess(file) {
    return super.requestFileSuccess(file);
  }
}
