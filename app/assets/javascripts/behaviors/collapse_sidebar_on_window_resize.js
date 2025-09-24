import $ from 'jquery';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';

/**
 * This behavior collapses the right sidebar
 * if the window size changes
 *
 * @sentrify
 */
export default () => {
  let bootstrapBreakpoint = PanelBreakpointInstance.getBreakpointSize();

  PanelBreakpointInstance.addResizeListener(() => {
    const oldBootstrapBreakpoint = bootstrapBreakpoint;
    bootstrapBreakpoint = PanelBreakpointInstance.getBreakpointSize();

    if (bootstrapBreakpoint !== oldBootstrapBreakpoint) {
      const breakpointSizes = ['md', 'sm', 'xs'];

      if (breakpointSizes.includes(bootstrapBreakpoint)) {
        const $toggleContainer = $('.js-sidebar-toggle-container');
        const isExpanded = $toggleContainer.data('is-expanded');
        const $expandIcon = $('.js-sidebar-expand');

        if (isExpanded) {
          const $sidebarGutterToggle = $expandIcon.closest('.js-sidebar-toggle');

          $sidebarGutterToggle.trigger('click');
        }

        const sidebarGutterVueToggleEl = document.querySelector('.js-sidebar-vue-toggle');

        // Sidebar has an icon which corresponds to collapsing the sidebar
        // only then trigger the click.
        if (
          sidebarGutterVueToggleEl &&
          !sidebarGutterVueToggleEl.classList.contains('js-sidebar-collapsed')
        ) {
          if (sidebarGutterVueToggleEl) {
            sidebarGutterVueToggleEl.click();
          }
        }
      }
    }
  });
};
