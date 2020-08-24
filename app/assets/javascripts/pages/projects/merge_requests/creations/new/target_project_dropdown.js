import $ from 'jquery';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default () => {
  const $targetProjectDropdown = $('.js-target-project');
  initDeprecatedJQueryDropdown($targetProjectDropdown, {
    selectable: true,
    fieldName: $targetProjectDropdown.data('fieldName'),
    filterable: true,
    id(obj, $el) {
      return $el.data('id');
    },
    toggleLabel(obj, $el) {
      return $el.text().trim();
    },
    clicked({ $el }) {
      $('.mr_target_commit').empty();
      const $targetBranchDropdown = $('.js-target-branch');
      $targetBranchDropdown.data('refsUrl', $el.data('refsUrl'));
      $targetBranchDropdown.data('deprecatedJQueryDropdown').clearMenu();
    },
  });
};
