import $ from 'jquery';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';

/**
 * This behavior collapses the right sidebar
 * if the window size changes
 *
 * @sentrify
 */
export default () => {
  const $sidebarGutterToggle = $('.js-sidebar-toggle');
  let bootstrapBreakpoint = bp.getBreakpointSize();

  $(window).on('resize.app', () => {
    const oldBootstrapBreakpoint = bootstrapBreakpoint;
    bootstrapBreakpoint = bp.getBreakpointSize();

    if (bootstrapBreakpoint !== oldBootstrapBreakpoint) {
      const breakpointSizes = ['md', 'sm', 'xs'];

      if (breakpointSizes.includes(bootstrapBreakpoint)) {
        const $gutterIcon = $sidebarGutterToggle.find('i');
        if ($gutterIcon.hasClass('fa-angle-double-right')) {
          $sidebarGutterToggle.trigger('click');
        }

        const sidebarGutterVueToggleEl = document.querySelector('.js-sidebar-vue-toggle');

        // Sidebar has an icon which corresponds to collapsing the sidebar
        // only then trigger the click.
        if (sidebarGutterVueToggleEl) {
          const collapseIcon = sidebarGutterVueToggleEl.querySelector('i.fa-angle-double-right');

          if (collapseIcon) {
            collapseIcon.click();
          }
        }
      }
    }
  });
};
