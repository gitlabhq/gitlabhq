import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';
import UsersSelect from '~/users_select';

export default class IssuableContext {
  constructor(currentUser) {
    this.reviewersSelect = new UsersSelect(currentUser, '.js-reviewer-search');

    this.reviewersSelect.dropdowns.forEach((glDropdownInstance) => {
      const jQueryWrapper = glDropdownInstance.dropdown;
      const domElement = jQueryWrapper[0];
      const content = domElement.querySelector('.dropdown-content');
      const loader = domElement.querySelector('.dropdown-loading');
      const spinner = loader.querySelector('.gl-spinner-container');
      const realParent = loader.parentNode;

      domElement.classList.add('non-blocking-loader');
      spinner.classList.remove('gl-mt-7');
      spinner.classList.add('gl-mt-2');

      jQueryWrapper.on('shown.bs.dropdown', () => {
        glDropdownInstance.filterInput.focus();
      });
      jQueryWrapper.on('toggle.on.loading.gl.dropdown filtering.gl.dropdown', () => {
        content.appendChild(loader);
      });
      jQueryWrapper.on('done.remote.loading.gl.dropdown done.filtering.gl.dropdown', () => {
        realParent.appendChild(loader);
      });
    });

    $('.issuable-sidebar .inline-update').on('change', 'select', function onClickSelect() {
      return $(this).submit();
    });
    $(document)
      .off('click', '.issuable-sidebar .dropdown-content a')
      .on('click', '.issuable-sidebar .dropdown-content a', (e) => e.preventDefault());

    $(document)
      .off('click', '.edit-link')
      .on('click', '.edit-link', function onClickEdit(e) {
        e.preventDefault();
        const $block = $(this).parents('.block');
        const $selectbox = $block.find('.selectbox');
        if ($selectbox.is(':visible')) {
          $selectbox.hide();
          $block.find('.value:not(.dont-hide)').show();
        } else {
          $selectbox.show();
          $block.find('.value:not(.dont-hide)').hide();
        }

        if ($selectbox.is(':visible')) {
          setTimeout(() => $block.find('.dropdown-menu-toggle').trigger('click'), 0);
        }
      });

    window.addEventListener('beforeunload', () => {
      // collapsed_gutter cookie hides the sidebar
      const bpBreakpoint = bp.getBreakpointSize();
      const supportedSizes = ['xs', 'sm', 'md'];

      if (supportedSizes.includes(bpBreakpoint)) {
        setCookie('collapsed_gutter', true);
      }
    });
  }
}
