/*= require blob/template_selector */
((global) => {

  class BlobCiYamlSelector extends TemplateSelector {
    requestFile(query) {
      return Api.gitlabCiYml(query.name, this.requestFileSuccess.bind(this));
    }
  };

  global.BlobCiYamlSelector = BlobCiYamlSelector;

  class BlobCiYamlSelectors {
    constructor({ editor, $dropdowns }) {
      this.editor = editor;
      this.$dropdowns = $dropdowns || $('.js-gitlab-ci-yml-selector');
      this.initSelectors();
    }

    initSelectors() {
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

})(window.gl || (window.gl = {}));
