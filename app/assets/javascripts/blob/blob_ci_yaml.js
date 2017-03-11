/* global Api */

import './template_selector';

class BlobCiYamlSelector extends gl.TemplateSelector {
  requestFile(query) {
    return Api.gitlabCiYml(query.name, this.requestFileSuccess.bind(this));
  }

  requestFileSuccess(file) {
    return super.requestFileSuccess(file);
  }
}

export default class BlobCiYamlSelectors {
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
        dropdown: $dropdown,
      });
    });
  }
}
