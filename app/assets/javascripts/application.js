/* eslint-disable */
// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
/*= require jquery2 */
/*= require jquery-ui/autocomplete */
/*= require jquery-ui/datepicker */
/*= require jquery-ui/draggable */
/*= require jquery-ui/effect-highlight */
/*= require jquery-ui/sortable */
/*= require jquery_ujs */
/*= require jquery.endless-scroll */
/*= require jquery.highlight */
/*= require jquery.waitforimages */
/*= require jquery.atwho */
/*= require jquery.scrollTo */
/*= require jquery.turbolinks */
/*= require jquery.tablesorter */
/*= require js.cookie */
/*= require turbolinks */
/*= require autosave */
/*= require bootstrap/affix */
/*= require bootstrap/alert */
/*= require bootstrap/button */
/*= require bootstrap/collapse */
/*= require bootstrap/dropdown */
/*= require bootstrap/modal */
/*= require bootstrap/scrollspy */
/*= require bootstrap/tab */
/*= require bootstrap/transition */
/*= require bootstrap/tooltip */
/*= require bootstrap/popover */
/*= require select2 */
/*= require underscore */
/*= require dropzone */
/*= require mousetrap */
/*= require mousetrap/pause */
/*= require shortcuts */
/*= require shortcuts_navigation */
/*= require shortcuts_dashboard_navigation */
/*= require shortcuts_issuable */
/*= require shortcuts_network */
/*= require jquery.nicescroll */
/*= require date.format */
/*= require_directory ./behaviors */
/*= require_directory ./blob */
/*= require_directory ./templates */
/*= require_directory ./commit */
/*= require_directory ./extensions */
/*= require_directory ./lib/utils */
/*= require_directory ./u2f */
/*= require_directory . */
/*= require fuzzaldrin-plus */

(function () {
  document.addEventListener('page:fetch', gl.utils.cleanupBeforeFetch);
  window.addEventListener('hashchange', gl.utils.shiftWindow);
  $.timeago.settings.allowFuture = true;

  window.onload = function () {
    // Scroll the window to avoid the topnav bar
    // https://github.com/twitter/bootstrap/issues/1768
    if (location.hash) {
      return setTimeout(gl.utils.shiftWindow, 100);
    }
  };

  $(function () {
    var $body = $('body');
    var $document = $(document);
    var $window = $(window);
    var $sidebarGutterToggle = $('.js-sidebar-toggle');
    var $flash = $('.flash-container');
    var bootstrapBreakpoint = bp.getBreakpointSize();
    var checkInitialSidebarSize;
    var fitSidebarForSize;

    // Set the default path for all cookies to GitLab's root directory
    Cookies.defaults.path = gon.relative_url_root || '/';

    gl.utils.preventDisabledButtons();
    $('.nav-sidebar').niceScroll({
      cursoropacitymax: '0.4',
      cursorcolor: '#FFF',
      cursorborder: '1px solid #FFF'
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
    checkInitialSidebarSize = function () {
      bootstrapBreakpoint = bp.getBreakpointSize();
      if (bootstrapBreakpoint === 'xs' || 'sm') {
        return $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
      }
    };
    $window.off('resize.app').on('resize.app', function () {
      return fitSidebarForSize();
    });
    gl.awardsHandler = new AwardsHandler();
    checkInitialSidebarSize();
    new Aside();

    // bind sidebar events
    new gl.Sidebar();
  });
}).call(this);
