import $ from 'jquery';
import Cookies from 'js-cookie';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import UsersSelect from './users_select';

export default class IssuableContext {
  constructor(currentUser) {
    this.userSelect = new UsersSelect(currentUser);

    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        $('select.select2').select2({
          width: 'resolve',
          dropdownAutoWidth: true,
        });
      })
      .catch(() => {});

    $('.issuable-sidebar .inline-update').on('change', 'select', function onClickSelect() {
      return $(this).submit();
    });
    $('.issuable-sidebar .inline-update').on('change', '.js-assignee', function onClickAssignee() {
      return $(this).submit();
    });
    $(document)
      .off('click', '.issuable-sidebar .dropdown-content a')
      .on('click', '.issuable-sidebar .dropdown-content a', e => e.preventDefault());

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
        Cookies.set('collapsed_gutter', true);
      }
    });
  }
}
