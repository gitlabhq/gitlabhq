import $ from 'jquery';
import Mousetrap from 'mousetrap';

export default class SidebarContext {
  constructor() {
    const $issuableSidebar = $('.js-issuable-update');

    Mousetrap.bind('l', () => SidebarContext.openSidebarDropdown($issuableSidebar.find('.js-labels-block')));

    $issuableSidebar
      .off('click', '.js-sidebar-dropdown-toggle')
      .on('click', '.js-sidebar-dropdown-toggle', function onClickEdit(e) {
        e.preventDefault();
        const $block = $(this).parents('.js-labels-block');
        const $selectbox = $block.find('.js-selectbox');

        // We use `:visible` to detect element visibility
        // since labels dropdown itself is handled by
        // labels_select.js which internally uses
        // $.hide() & $.show() to toggle elements
        // which requires us to use `display: none;`
        // in `labels_select/base.vue` as well.
        // see: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4773#note_61844731
        if ($selectbox.is(':visible')) {
          $selectbox.hide();
          $block.find('.js-value').show();
        } else {
          $selectbox.show();
          $block.find('.js-value').hide();
        }

        if ($selectbox.is(':visible')) {
          setTimeout(() => $block.find('.js-label-select').trigger('click'), 0);
        }
      });
  }

  static openSidebarDropdown($block) {
    $block.find('.js-sidebar-dropdown-toggle').trigger('click');
  }
}
