/* eslint-disable import/first */
/* global $ */

import jQuery from 'jquery';
import Cookies from 'js-cookie';
import svg4everybody from 'svg4everybody';

// expose common libraries as globals (TODO: remove these)
window.jQuery = jQuery;
window.$ = jQuery;

// lib/utils
import { handleLocationHash, addSelectOnFocusBehaviour } from './lib/utils/common_utils';
import { localTimeAgo } from './lib/utils/datetime_utility';
import { getLocationHash, visitUrl } from './lib/utils/url_utility';

// behaviors
import './behaviors/';

// everything else
import loadAwardsHandler from './awards_handler';
import bp from './breakpoints';
import initConfirmDangerModal from './confirm_danger_modal';
import Flash, { removeFlashClickListener } from './flash';
import './gl_dropdown';
import initTodoToggle from './header';
import initImporterStatus from './importer_status';
import initLayoutNav from './layout_nav';
import './feature_highlight/feature_highlight_options';
import LazyLoader from './lazy_loader';
import initLogoAnimation from './logo';
import './milestone_select';
import './projects_dropdown';
import initBreadcrumbs from './breadcrumb';

import initDispatcher from './dispatcher';

// inject test utilities if necessary
if (process.env.NODE_ENV !== 'production' && gon && gon.test_env) {
  $.fx.off = true;
  import(/* webpackMode: "eager" */ './test_utils/');
}

svg4everybody();

document.addEventListener('beforeunload', () => {
  // Unbind scroll events
  $(document).off('scroll');
  // Close any open tooltips
  $('.has-tooltip, [data-toggle="tooltip"]').tooltip('destroy');
  // Close any open popover
  $('[data-toggle="popover"]').popover('destroy');
});

window.addEventListener('hashchange', handleLocationHash);
window.addEventListener('load', function onLoad() {
  window.removeEventListener('load', onLoad, false);
  handleLocationHash();
}, false);

gl.lazyLoader = new LazyLoader({
  scrollContainer: window,
  observerNode: '#content-body',
});

document.addEventListener('DOMContentLoaded', () => {
  const $body = $('body');
  const $document = $(document);
  const $window = $(window);
  const $sidebarGutterToggle = $('.js-sidebar-toggle');
  let bootstrapBreakpoint = bp.getBreakpointSize();

  initBreadcrumbs();
  initLayoutNav();
  initImporterStatus();
  initTodoToggle();
  initLogoAnimation();

  // Set the default path for all cookies to GitLab's root directory
  Cookies.defaults.path = gon.relative_url_root || '/';

  // `hashchange` is not triggered when link target is already in window.location
  $body.on('click', 'a[href^="#"]', function clickHashLinkCallback() {
    const href = this.getAttribute('href');
    if (href.substr(1) === getLocationHash()) {
      setTimeout(handleLocationHash, 1);
    }
  });

  if (bootstrapBreakpoint === 'xs') {
    const $rightSidebar = $('aside.right-sidebar, .layout-page');

    $rightSidebar
      .removeClass('right-sidebar-expanded')
      .addClass('right-sidebar-collapsed');
  }

  // prevent default action for disabled buttons
  $('.btn').click(function clickDisabledButtonCallback(e) {
    if ($(this).hasClass('disabled')) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return false;
    }

    return true;
  });

  addSelectOnFocusBehaviour('.js-select-on-focus');

  $('.remove-row').on('ajax:success', function removeRowAjaxSuccessCallback() {
    $(this).tooltip('destroy')
      .closest('li')
      .fadeOut();
  });

  $('.js-remove-tr').on('ajax:before', function removeTRAjaxBeforeCallback() {
    $(this).hide();
  });

  $('.js-remove-tr').on('ajax:success', function removeTRAjaxSuccessCallback() {
    $(this).closest('tr').fadeOut();
  });

  // Initialize select2 selects
  $('select.select2').select2({
    width: 'resolve',
    dropdownAutoWidth: true,
  });

  // Close select2 on escape
  $('.js-select2').on('select2-close', () => {
    setTimeout(() => {
      $('.select2-container-active').removeClass('select2-container-active');
      $(':focus').blur();
    }, 1);
  });

  // Initialize tooltips
  $.fn.tooltip.Constructor.DEFAULTS.trigger = 'hover';
  $body.tooltip({
    selector: '.has-tooltip, [data-toggle="tooltip"]',
    placement(tip, el) {
      return $(el).data('placement') || 'bottom';
    },
  });

  // Initialize popovers
  $body.popover({
    selector: '[data-toggle="popover"]',
    trigger: 'focus',
    // set the viewport to the main content, excluding the navigation bar, so
    // the navigation can't overlap the popover
    viewport: '.layout-page',
  });

  // Form submitter
  $('.trigger-submit').on('change', function triggerSubmitCallback() {
    $(this).parents('form').submit();
  });

  localTimeAgo($('abbr.timeago, .js-timeago'), true);

  // Disable form buttons while a form is submitting
  $body.on('ajax:complete, ajax:beforeSend, submit', 'form', function ajaxCompleteCallback(e) {
    const $buttons = $('[type="submit"], .js-disable-on-submit', this);
    switch (e.type) {
      case 'ajax:beforeSend':
      case 'submit':
        return $buttons.disable();
      default:
        return $buttons.enable();
    }
  });

  $(document).ajaxError((e, xhrObj) => {
    const ref = xhrObj.status;

    if (ref === 401) {
      Flash('You need to be logged in.');
    } else if (ref === 404 || ref === 500) {
      Flash('Something went wrong on our end.');
    }
  });

  // Commit show suppressed diff
  $document.on('click', '.diff-content .js-show-suppressed-diff', function showDiffCallback() {
    const $container = $(this).parent();
    $container.next('table').show();
    $container.remove();
  });

  $('.navbar-toggle').on('click', () => {
    $('.header-content').toggleClass('menu-expanded');
    gl.lazyLoader.loadCheck();
  });

  // Show/hide comments on diff
  $body.on('click', '.js-toggle-diff-comments', function toggleDiffCommentsCallback(e) {
    const $this = $(this);
    const notesHolders = $this.closest('.diff-file').find('.notes_holder');

    e.preventDefault();

    $this.toggleClass('active');

    if ($this.hasClass('active')) {
      notesHolders.show().find('.hide, .content').show();
    } else {
      notesHolders.hide().find('.content').hide();
    }

    $(document).trigger('toggle.comments');
  });

  $document.on('click', '.js-confirm-danger', (e) => {
    e.preventDefault();
    const $btn = $(e.target);
    const $form = $btn.closest('form');
    const text = $btn.data('confirmDangerMessage');
    initConfirmDangerModal($form, text);
  });

  $document.on('breakpoint:change', (e, breakpoint) => {
    if (breakpoint === 'sm' || breakpoint === 'xs') {
      const $gutterIcon = $sidebarGutterToggle.find('i');
      if ($gutterIcon.hasClass('fa-angle-double-right')) {
        $sidebarGutterToggle.trigger('click');
      }
    }
  });

  function fitSidebarForSize() {
    const oldBootstrapBreakpoint = bootstrapBreakpoint;
    bootstrapBreakpoint = bp.getBreakpointSize();

    if (bootstrapBreakpoint !== oldBootstrapBreakpoint) {
      $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
    }
  }

  $window.on('resize.app', fitSidebarForSize);

  loadAwardsHandler();

  $('form.filter-form').on('submit', function filterFormSubmitCallback(event) {
    const link = document.createElement('a');
    link.href = this.action;

    const action = `${this.action}${link.search === '' ? '?' : '&'}`;

    event.preventDefault();
    visitUrl(`${action}${$(this).serialize()}`);
  });

  const flashContainer = document.querySelector('.flash-container');

  if (flashContainer && flashContainer.children.length) {
    flashContainer.querySelectorAll('.flash-alert, .flash-notice, .flash-success').forEach((flashEl) => {
      removeFlashClickListener(flashEl);
    });
  }

  initDispatcher();
});
