/* global Api */

import BlobCiYamlSelector from './blob_ci_yaml_selector';

export default class BlobCiYamlSelectors {
  constructor({ editor, $dropdowns }) {
    this.$dropdowns = $dropdowns || $('.js-gitlab-ci-yml-selector');
    this.initSelectors(editor);
  }

  initSelectors(editor) {
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
