/* eslint-disable func-names, space-before-function-paren, no-var, quotes, consistent-return, prefer-arrow-callback, comma-dangle, object-shorthand, no-new, max-len, no-multi-spaces, import/newline-after-import, import/first */
/* global ConfirmDangerModal */

import jQuery from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import Dropzone from 'dropzone';
import Sortable from 'vendor/Sortable';
import svg4everybody from 'svg4everybody';

// libraries with import side-effects
import 'mousetrap';
import 'mousetrap/plugins/pause/mousetrap-pause';

// expose common libraries as globals (TODO: remove these)
window.jQuery = jQuery;
window.$ = jQuery;
window._ = _;
window.Dropzone = Dropzone;
window.Sortable = Sortable;

// templates
import './templates/issuable_template_selector';
import './templates/issuable_template_selectors';

import './commit/image_file';

// lib/utils
import { handleLocationHash } from './lib/utils/common_utils';
import { localTimeAgo, renderTimeago } from './lib/utils/datetime_utility';
import { getLocationHash, visitUrl } from './lib/utils/url_utility';

// behaviors
import './behaviors/';

// everything else
import loadAwardsHandler from './awards_handler';
import bp from './breakpoints';
import './confirm_danger_modal';
import Flash, { removeFlashClickListener } from './flash';
import './gl_dropdown';
import initTodoToggle from './header';
import initImporterStatus from './importer_status';
import initLayoutNav from './layout_nav';
import LazyLoader from './lazy_loader';
import './line_highlighter';
import initLogoAnimation from './logo';
import './milestone_select';
import './projects_dropdown';
import './render_gfm';
import initBreadcrumbs from './breadcrumb';

// EE-only scripts
import initEETrialBanner from 'ee/ee_trial_banner';

import './dispatcher';

// eslint-disable-next-line global-require, import/no-commonjs
if (process.env.NODE_ENV !== 'production') require('./test_utils/');

Dropzone.autoDiscover = false;

svg4everybody();

document.addEventListener('beforeunload', function () {
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
  observerNode: '#content-body'
});

$(function () {
  var $body = $('body');
  var $document = $(document);
  var $window = $(window);
  var $sidebarGutterToggle = $('.js-sidebar-toggle');
  var bootstrapBreakpoint = bp.getBreakpointSize();
  var fitSidebarForSize;

  initBreadcrumbs();
  initLayoutNav();
  initImporterStatus();
  initTodoToggle();
  initLogoAnimation();

  // Set the default path for all cookies to GitLab's root directory
  Cookies.defaults.path = gon.relative_url_root || '/';

  // `hashchange` is not triggered when link target is already in window.location
  $body.on('click', 'a[href^="#"]', function() {
    var href = this.getAttribute('href');
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
  $('.btn').click(function(e) {
    if ($(this).hasClass('disabled')) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return false;
    }
  });

  $('.js-select-on-focus').on('focusin', function () {
    return $(this).select().one('mouseup', function (e) {
      return e.preventDefault();
    });
  // Click a .js-select-on-focus field, select the contents
  // Prevent a mouseup event from deselecting the input
  });
  $('.remove-row').bind('ajax:success', function () {
    $(this).tooltip('destroy')
      .closest('li')
      .fadeOut();
  });
  $('.js-remove-tr').bind('ajax:before', function () {
    return $(this).hide();
  });
  $('.js-remove-tr').bind('ajax:success', function () {
    return $(this).closest('tr').fadeOut();
  });
  $('select.select2').select2({
    width: 'resolve',
    // Initialize select2 selects
    dropdownAutoWidth: true
  });
  $('.js-select2').bind('select2-close', function () {
    return setTimeout((function () {
      $('.select2-container-active').removeClass('select2-container-active');
      return $(':focus').blur();
    }), 1);
  // Close select2 on escape
  });
  // Initialize tooltips
  $.fn.tooltip.Constructor.DEFAULTS.trigger = 'hover';
  $body.tooltip({
    selector: '.has-tooltip, [data-toggle="tooltip"]',
    placement: function (tip, el) {
      return $(el).data('placement') || 'bottom';
    }
  });
  // Initialize popovers
  $body.popover({
    selector: '[data-toggle="popover"]',
    trigger: 'focus',
    // set the viewport to the main content, excluding the navigation bar, so
    // the navigation can't overlap the popover
    viewport: '.layout-page'
  });
  $('.trigger-submit').on('change', function () {
    return $(this).parents('form').submit();
  // Form submitter
  });
  localTimeAgo($('abbr.timeago, .js-timeago'), true);
  // Disable form buttons while a form is submitting
  $body.on('ajax:complete, ajax:beforeSend, submit', 'form', function (e) {
    var buttons;
    buttons = $('[type="submit"], .js-disable-on-submit', this);
    switch (e.type) {
      case 'ajax:beforeSend':
      case 'submit':
        return buttons.disable();
      default:
        return buttons.enable();
    }
  });
  $(document).ajaxError(function (e, xhrObj) {
    var ref = xhrObj.status;
    if (xhrObj.status === 401) {
      return new Flash('You need to be logged in.', 'alert');
    } else if (ref === 404 || ref === 500) {
      return new Flash('Something went wrong on our end.', 'alert');
    }
  });
  $('.account-box').hover(function () {
    // Show/Hide the profile menu when hovering the account box
    return $(this).toggleClass('hover');
  });
  $document.on('click', '.diff-content .js-show-suppressed-diff', function () {
    var $container;
    $container = $(this).parent();
    $container.next('table').show();
    return $container.remove();
  // Commit show suppressed diff
  });
  $('.navbar-toggle').on('click', () => {
    $('.header-content').toggleClass('menu-expanded');
    gl.lazyLoader.loadCheck();
  });
  // Show/hide comments on diff
  $body.on('click', '.js-toggle-diff-comments', function (e) {
    var $this = $(this);
    var notesHolders = $this.closest('.diff-file').find('.notes_holder');
    $this.toggleClass('active');
    if ($this.hasClass('active')) {
      notesHolders.show().find('.hide, .content').show();
    } else {
      notesHolders.hide().find('.content').hide();
    }
    $(document).trigger('toggle.comments');
    return e.preventDefault();
  });
  $document.off('click', '.js-confirm-danger');
  $document.on('click', '.js-confirm-danger', function (e) {
    var btn = $(e.target);
    var form = btn.closest('form');
    var text = btn.data('confirm-danger-message');
    var warningMessage = btn.data('warning-message');
    e.preventDefault();
    return new ConfirmDangerModal(form, text, {
      warningMessage: warningMessage
    });
  });
  $('input[type="search"]').each(function () {
    var $this = $(this);
    $this.attr('value', $this.val());
  });
  $document.off('keyup', 'input[type="search"]').on('keyup', 'input[type="search"]', function () {
    var $this;
    $this = $(this);
    return $this.attr('value', $this.val());
  });
  $document.off('breakpoint:change').on('breakpoint:change', function (e, breakpoint) {
    var $gutterIcon;
    if (breakpoint === 'sm' || breakpoint === 'xs') {
      $gutterIcon = $sidebarGutterToggle.find('i');
      if ($gutterIcon.hasClass('fa-angle-double-right')) {
        return $sidebarGutterToggle.trigger('click');
      }
    }
  });
  fitSidebarForSize = function () {
    var oldBootstrapBreakpoint;
    oldBootstrapBreakpoint = bootstrapBreakpoint;
    bootstrapBreakpoint = bp.getBreakpointSize();
    if (bootstrapBreakpoint !== oldBootstrapBreakpoint) {
      return $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
    }
  };
  $window.off('resize.app').on('resize.app', function () {
    return fitSidebarForSize();
  });
  loadAwardsHandler();

  renderTimeago();

  $('form.filter-form').on('submit', function (event) {
    const link = document.createElement('a');
    link.href = this.action;

    const action = `${this.action}${link.search === '' ? '?' : '&'}`;

    event.preventDefault();
    visitUrl(`${action}${$(this).serialize()}`);
  });

  /**
   * EE specific scripts
   */
  $('#modal-upload-trial-license').modal('show');
  const flashContainer = document.querySelector('.flash-container');

  if (flashContainer && flashContainer.children.length) {
    flashContainer.querySelectorAll('.flash-alert, .flash-notice, .flash-success').forEach((flashEl) => {
      removeFlashClickListener(flashEl);
    });
  }

  // EE specific calls
  initEETrialBanner();
});
