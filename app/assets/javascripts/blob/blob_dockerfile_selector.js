/* global Api */

import TemplateSelector from './template_selector';

(() => {
  const global = window.gl || (window.gl = {});

  class BlobDockerfileSelector extends TemplateSelector {
    requestFile(query) {
      return Api.dockerfileYml(query.name, this.requestFileSuccess.bind(this));
    }

    requestFileSuccess(file) {
      return super.requestFileSuccess(file);
    }
  }

  global.BlobDockerfileSelector = BlobDockerfileSelector;
})();
