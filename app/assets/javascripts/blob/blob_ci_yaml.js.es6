/*= require blob/template_selector */
((global) => {

  class BlobCiYamlSelector extends TemplateSelector {
    constructor(...args) {
      super(...args);
    }

    requestFile(query) {
      return Api.gitlabCiYml(query.name, this.requestFileSuccess.bind(this));
    };
  };

  global.BlobCiYamlSelector = BlobCiYamlSelector;

  class BlobCiYamlSelectors {
    constructor(opts) {
      this.$dropdowns = opts.$dropdowns || $('.js-gitlab-ci-yml-selector');
      this.editor = opts.editor;
      this.initSelectors();
    }

    initSelectors() {
      this.$dropdowns.each((i, dropdown) => {
        const $dropdown = $(dropdown);
        return new BlobCiYamlSelector({
          pattern: /(.gitlab-ci.yml)/,
          data: $dropdown.data('data'),
          wrapper: $dropdown.closest('.js-gitlab-ci-yml-selector-wrap'),
          dropdown: $dropdown,
          editor: this.editor
        });
      });
    }
  }

  global.BlobCiYamlSelectors = BlobCiYamlSelectors;

})(window.gl || (window.gl = {}));
