/*= require blob/template_selector */
((global) => {

  class BlobCiYamlSelector extends gl.TemplateSelector {
    requestFile(query) {
      return Api.gitlabCiYml(query.name, this.requestFileSuccess.bind(this));
    }

    requestFileSuccess(file) {
      return super.requestFileSuccess(file);
    }
  }

  global.BlobCiYamlSelector = BlobCiYamlSelector;

  class BlobCiYamlSelectors {
    constructor({ editor, $dropdowns } = {}) {
      this.editor = editor;
      this.$dropdowns = $dropdowns || $('.js-gitlab-ci-yml-selector');
      this.initSelectors();
    }

    initSelectors() {
      const editor = this.editor;
      this.$dropdowns.each((i, dropdown) => {
        const $dropdown = $(dropdown);
        return new BlobCiYamlSelector({
          editor,
          pattern: /(.gitlab-ci.yml)/,
          data: $dropdown.data('data'),
          wrapper: $dropdown.closest('.js-gitlab-ci-yml-selector-wrap'),
          dropdown: $dropdown
        });
      });
    }
  }

  global.BlobCiYamlSelectors = BlobCiYamlSelectors;

    class BlobDockerfileSelector extends gl.TemplateSelector {
        requestFile(query) {
            return Api.dockerfileYml(query.name, this.requestFileSuccess.bind(this));
        }

        requestFileSuccess(file) {
            return super.requestFileSuccess(file);
        }
    }

    global.BlobDockerfileSelector = BlobDockerfileSelector;

    class BlobDockerfileSelectors {
        constructor({ editor, $dropdowns } = {}) {
            this.editor = editor;
            this.$dropdowns = $dropdowns || $('.js-dockerfile-selector');
            this.initSelectors();
        }

        initSelectors() {
            const editor = this.editor;
            this.$dropdowns.each((i, dropdown) => {
                const $dropdown = $(dropdown);
                return new BlobDockerfileSelector({
                    editor,
                    pattern: /(Dockerfile)/,
                    data: $dropdown.data('data'),
                    wrapper: $dropdown.closest('.js-dockerfile-selector-wrap'),
                    dropdown: $dropdown
                });
            });
        }
    }

    global.BlobDockerfileSelectors = BlobDockerfileSelectors;

})(window.gl || (window.gl = {}));
