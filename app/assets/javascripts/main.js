/* eslint-disable func-names, space-before-function-paren, no-var, quotes, consistent-return, prefer-arrow-callback, comma-dangle, object-shorthand, no-new, max-len, no-multi-spaces, import/newline-after-import, import/first */
/* global bp */
/* global Flash */
/* global ConfirmDangerModal */
/* global Aside */

import jQuery from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import Pikaday from 'pikaday';
import Dropzone from 'dropzone';
import Sortable from 'vendor/Sortable';

// libraries with import side-effects
import 'mousetrap';
import 'mousetrap/plugins/pause/mousetrap-pause';
import 'vendor/fuzzaldrin-plus';

// extensions
import './extensions/array';

// expose common libraries as globals (TODO: remove these)
window.jQuery = jQuery;
window.$ = jQuery;
window._ = _;
window.Pikaday = Pikaday;
window.Dropzone = Dropzone;
window.Sortable = Sortable;

// shortcuts
import './shortcuts';
import './shortcuts_blob';
import './shortcuts_dashboard_navigation';
import './shortcuts_navigation';
import './shortcuts_find_file';
import './shortcuts_issuable';
import './shortcuts_network';

// behaviors
import './behaviors/';

// templates
import './templates/issuable_template_selector';
import './templates/issuable_template_selectors';

// commit
import './commit/file';
import './commit/image_file';

// lib/utils
import './lib/utils/animate';
import './lib/utils/bootstrap_linked_tabs';
import './lib/utils/common_utils';
import './lib/utils/datetime_utility';
import './lib/utils/pretty_time';
import './lib/utils/text_utility';
import './lib/utils/url_utility';

// u2f
import './u2f/authenticate';
import './u2f/error';
import './u2f/register';
import './u2f/util';

// everything else
import './abuse_reports';
import './activities';
import './admin';
import './ajax_loading_spinner';
import './api';
import './aside';
import './autosave';
import loadAwardsHandler from './awards_handler';
import './breakpoints';
import './broadcast_message';
import './build';
import './build_artifacts';
import './build_variables';
import './ci_lint_editor';
import './commit';
import './commits';
import './compare';
import './compare_autocomplete';
import './confirm_danger_modal';
import './copy_as_gfm';
import './copy_to_clipboard';
import './create_label';
import './diff';
import './dispatcher';
import './dropzone_input';
import './due_date_select';
import './files_comment_button';
import './flash';
import './gl_dropdown';
import './gl_field_error';
import './gl_field_errors';
import './gl_form';
import './group_avatar';
import './group_label_subscription';
import './groups_select';
import './header';
import './importer_status';
import './issuable_index';
import './issuable_context';
import './issuable_form';
import './issue';
import './issue_status_select';
import './label_manager';
import './labels';
import './labels_select';
import './layout_nav';
import LazyLoader from './lazy_loader';
import './line_highlighter';
import './logo';
import './member_expiration_date';
import './members';
import './merge_request';
import './merge_request_tabs';
import './milestone';
import './milestone_select';
import './mini_pipeline_graph_dropdown';
import './namespace_select';
import './new_branch_form';
import './new_commit_form';
import './notes';
import './notifications_dropdown';
import './notifications_form';
import './pager';
import './pipelines';
import './preview_markdown';
import './project';
import './project_avatar';
import './project_find_file';
import './project_fork';
import './project_import';
import './project_label_subscription';
import './project_new';
import './project_select';
import './project_show';
import './project_variables';
import './projects_list';
import './render_gfm';
import './render_math';
import './right_sidebar';
import './search';
import './search_autocomplete';
import './smart_interval';
import './snippets_list';
import './star';
import './subscription';
import './subscription_select';
import './syntax_highlight';

// EE-only scripts
import './admin_email_select';
import './application_settings';
import './approvals';
import './ee_trial_banner';
import './ldap_groups_select';
import './path_locks';
import './weight_select';

// eslint-disable-next-line global-require, import/no-commonjs
if (process.env.NODE_ENV !== 'production') require('./test_utils/');

document.addEventListener('beforeunload', function () {
  // Unbind scroll events
  $(document).off('scroll');
  // Close any open tooltips
  $('.has-tooltip, [data-toggle="tooltip"]').tooltip('destroy');
});

window.addEventListener('hashchange', gl.utils.handleLocationHash);
window.addEventListener('load', function onLoad() {
  window.removeEventListener('load', onLoad, false);
  gl.utils.handleLocationHash();
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
  var $flash = $('.flash-container');
  var bootstrapBreakpoint = bp.getBreakpointSize();
  var fitSidebarForSize;

  // Set the default path for all cookies to GitLab's root directory
  Cookies.defaults.path = gon.relative_url_root || '/';

  // `hashchange` is not triggered when link target is already in window.location
  $body.on('click', 'a[href^="#"]', function() {
    var href = this.getAttribute('href');
    if (href.substr(1) === gl.utils.getLocationHash()) {
      setTimeout(gl.utils.handleLocationHash, 1);
    }
  });

  if (bootstrapBreakpoint === 'xs') {
    const $rightSidebar = $('aside.right-sidebar, .page-with-sidebar');

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
  $('.trigger-submit').on('change', function () {
    return $(this).parents('form').submit();
  // Form submitter
  });
  gl.utils.localTimeAgo($('abbr.timeago, .js-timeago'), true);
  // Flash
  if ($flash.length > 0) {
    $flash.click(function () {
      return $(this).fadeOut();
    });
    $flash.show();
  }
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
  $('.navbar-toggle').on('click', () => $('.header-content').toggleClass('menu-expanded'));
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
  new Aside();

  gl.utils.renderTimeago();

  $(document).trigger('init.scrolling-tabs');
});
