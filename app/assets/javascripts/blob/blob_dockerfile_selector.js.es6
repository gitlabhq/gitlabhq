/* global Api */
/*= require blob/template_selector */

(() => {
  const global = window.gl || (window.gl = {});

  class BlobDockerfileSelector extends gl.TemplateSelector {
    requestFile(query) {
      return Api.dockerfileYml(query.name, this.requestFileSuccess.bind(this));
    }

    requestFileSuccess(file) {
      return super.requestFileSuccess(file);
    }
  }

  global.BlobDockerfileSelector = BlobDockerfileSelector;
})();
