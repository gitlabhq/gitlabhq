/* eslint-disable func-names, space-before-function-paren, no-var, quotes, consistent-return, prefer-arrow-callback, comma-dangle, object-shorthand, no-new, max-len, no-multi-spaces, import/newline-after-import */
/* global bp */
/* global Cookies */
/* global Flash */
/* global ConfirmDangerModal */
/* global AwardsHandler */
/* global Aside */

window.$ = window.jQuery = require('jquery');
require('jquery-ui/ui/autocomplete');
require('jquery-ui/ui/draggable');
require('jquery-ui/ui/effect-highlight');
require('jquery-ui/ui/sortable');
require('jquery-ujs');
require('vendor/jquery.endless-scroll');
require('vendor/jquery.highlight');
require('vendor/jquery.waitforimages');
require('vendor/jquery.caret');
require('vendor/jquery.atwho');
require('vendor/jquery.scrollTo');
require('vendor/jquery.tablesorter');
window.Cookies = require('js-cookie');
require('./autosave');
require('bootstrap/js/affix');
require('bootstrap/js/alert');
require('bootstrap/js/button');
require('bootstrap/js/collapse');
require('bootstrap/js/dropdown');
require('bootstrap/js/modal');
require('bootstrap/js/scrollspy');
require('bootstrap/js/tab');
require('bootstrap/js/transition');
require('bootstrap/js/tooltip');
require('bootstrap/js/popover');
require('select2/select2.js');
window.Pikaday = require('pikaday');
window._ = require('underscore');
window.Dropzone = require('dropzone');
window.Sortable = require('vendor/Sortable');
require('mousetrap');
require('mousetrap/plugins/pause/mousetrap-pause');
require('./shortcuts');
require('./shortcuts_navigation');
require('./shortcuts_dashboard_navigation');
require('./shortcuts_issuable');
require('./shortcuts_network');
require('vendor/jquery.nicescroll');
require('./geo/geo_bundle');
require('./ajax_loading_spinner');

// behaviors
require('./behaviors/autosize');
require('./behaviors/details_behavior');
require('./behaviors/quick_submit');
require('./behaviors/requires_input');
require('./behaviors/toggler_behavior');

// blob
require('./blob/blob_ci_yaml');
require('./blob/blob_dockerfile_selector');
require('./blob/blob_dockerfile_selectors');
require('./blob/blob_file_dropzone');
require('./blob/blob_gitignore_selector');
require('./blob/blob_gitignore_selectors');
require('./blob/blob_license_selector');
require('./blob/blob_license_selectors');
require('./blob/template_selector');

// templates
require('./templates/issuable_template_selector');
require('./templates/issuable_template_selectors');

// commit
require('./commit/file.js');
require('./commit/image_file.js');

// extensions
require('./extensions/array');
require('./extensions/custom_event');
require('./extensions/element');
require('./extensions/jquery');
require('./extensions/object');

// lib/utils
require('./lib/utils/animate');
require('./lib/utils/bootstrap_linked_tabs');
require('./lib/utils/common_utils');
require('./lib/utils/datetime_utility');
require('./lib/utils/notify');
require('./lib/utils/pretty_time');
require('./lib/utils/text_utility');
require('./lib/utils/type_utility');
require('./lib/utils/url_utility');

// u2f
require('./u2f/authenticate');
require('./u2f/error');
require('./u2f/register');
require('./u2f/util');

// droplab
require('./droplab/droplab');
require('./droplab/droplab_ajax');
require('./droplab/droplab_ajax_filter');
require('./droplab/droplab_filter');

// everything else
require('./abuse_reports');
require('./activities');
require('./admin');
require('./api');
require('./aside');
require('./autosave');
require('./awards_handler');
require('./breakpoints');
require('./broadcast_message');
require('./build');
require('./build_artifacts');
require('./build_variables');
require('./ci_lint_editor');
require('./commit');
require('./commits');
require('./compare');
require('./compare_autocomplete');
require('./confirm_danger_modal');
require('./copy_as_gfm');
require('./copy_to_clipboard');
require('./create_label');
require('./diff');
require('./dispatcher');
require('./dropzone_input');
require('./due_date_select');
require('./files_comment_button');
require('./flash');
require('./gfm_auto_complete');
require('./gl_dropdown');
require('./gl_field_error');
require('./gl_field_errors');
require('./gl_form');
require('./group_avatar');
require('./group_label_subscription');
require('./groups_select');
require('./header');
require('./importer_status');
require('./issuable');
require('./issuable_context');
require('./issuable_form');
require('./issue');
require('./issue_status_select');
require('./issues_bulk_assignment');
require('./label_manager');
require('./labels');
require('./labels_select');
require('./layout_nav');
require('./line_highlighter');
require('./logo');
require('./member_expiration_date');
require('./members');
require('./merge_request');
require('./merge_request_tabs');
require('./merge_request_widget');
require('./merged_buttons');
require('./milestone');
require('./milestone_select');
require('./mini_pipeline_graph_dropdown');
require('./namespace_select');
require('./new_branch_form');
require('./new_commit_form');
require('./notes');
require('./notifications_dropdown');
require('./notifications_form');
require('./pager');
require('./pipelines');
require('./preview_markdown');
require('./project');
require('./project_avatar');
require('./project_find_file');
require('./project_fork');
require('./project_import');
require('./project_label_subscription');
require('./project_new');
require('./project_select');
require('./project_show');
require('./project_variables');
require('./projects_list');
require('./render_gfm');
require('./render_math');
require('./right_sidebar');
require('./search');
require('./search_autocomplete');
require('./shortcuts');
require('./shortcuts_blob');
require('./shortcuts_dashboard_navigation');
require('./shortcuts_find_file');
require('./shortcuts_issuable');
require('./shortcuts_navigation');
require('./shortcuts_network');
require('./signin_tabs_memoizer');
require('./single_file_diff');
require('./smart_interval');
require('./snippets_list');
require('./star');
require('./subbable_resource');
require('./subscription');
require('./subscription_select');
require('./syntax_highlight');
require('./task_list');
require('./todos');
require('./tree');
require('./user');
require('./user_tabs');
require('./username_validator');
require('./users_select');
require('./version_check_image');
require('./visibility_select');
require('./wikis');
require('./zen_mode');

require('vendor/fuzzaldrin-plus');
require('es6-promise').polyfill();

// EE-only scripts
require('./admin_email_select');
require('./application_settings');
require('./approvals');
require('./ldap_groups_select');
require('./path_locks');
require('./weight_select');

(function () {
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
      placement: function (_, el) {
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
      buttons = $('[type="submit"]', this);
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
    $('.navbar-toggle').on('click', function () {
      $('.header-content .title').toggle();
      $('.header-content .header-logo').toggle();
      $('.header-content .navbar-collapse').toggle();
      return $('.navbar-toggle').toggleClass('active');
    });
    // Show/hide comments on diff
    $body.on('click', '.js-toggle-diff-comments', function (e) {
      var $this = $(this);
      var notesHolders = $this.closest('.diff-file').find('.notes_holder');
      $this.toggleClass('active');
      if ($this.hasClass('active')) {
        notesHolders.show().find('.hide').show();
      } else {
        notesHolders.hide();
      }
      $this.trigger('blur');
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
    gl.awardsHandler = new AwardsHandler();
    new Aside();

    gl.utils.initTimeagoTimeout();
  });
}).call(window);
