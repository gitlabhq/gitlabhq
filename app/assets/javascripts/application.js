// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
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
/*= require jquery.cookie */
/*= require jquery.endless-scroll */
/*= require jquery.highlight */
/*= require jquery.waitforimages */
/*= require jquery.atwho */
/*= require jquery.scrollTo */
/*= require jquery.turbolinks */
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

(function() {
  window.slugify = function(text) {
    return text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase();
  };

  window.ajaxGet = function(url) {
    return $.ajax({
      type: "GET",
      url: url,
      dataType: "script"
    });
  };

  window.split = function(val) {
    return val.split(/,\s*/);
  };

  window.extractLast = function(term) {
    return split(term).pop();
  };

  window.rstrip = function(val) {
    if (val) {
      return val.replace(/\s+$/, '');
    } else {
      return val;
    }
  };

  // Disable button if text field is empty
  window.disableButtonIfEmptyField = function(field_selector, button_selector) {
    var closest_submit, field;
    field = $(field_selector);
    closest_submit = field.closest('form').find(button_selector);
    if (rstrip(field.val()) === "") {
      closest_submit.disable();
    }
    return field.on('input', function() {
      if (rstrip($(this).val()) === "") {
        return closest_submit.disable();
      } else {
        return closest_submit.enable();
      }
    });
  };

  // Disable button if any input field with given selector is empty
  window.disableButtonIfAnyEmptyField = function(form, form_selector, button_selector) {
    var closest_submit, updateButtons;
    closest_submit = form.find(button_selector);
    updateButtons = function() {
      var filled;
      filled = true;
      form.find('input').filter(form_selector).each(function() {
        return filled = rstrip($(this).val()) !== "" || !$(this).attr('required');
      });
      if (filled) {
        return closest_submit.enable();
      } else {
        return closest_submit.disable();
      }
    };
    updateButtons();
    return form.keyup(updateButtons);
  };

  window.sanitize = function(str) {
    return str.replace(/<(?:.|\n)*?>/gm, '');
  };

  window.unbindEvents = function() {
    return $(document).off('scroll');
  };

  window.shiftWindow = function() {
    return scrollBy(0, -100);
  };

  document.addEventListener("page:fetch", unbindEvents);

  window.addEventListener("hashchange", shiftWindow);

  window.onload = function() {
    // Scroll the window to avoid the topnav bar
    // https://github.com/twitter/bootstrap/issues/1768
    if (location.hash) {
      return setTimeout(shiftWindow, 100);
    }
  };

  $(function() {
    var $body, $document, $sidebarGutterToggle, $window, bootstrapBreakpoint, checkInitialSidebarSize, fitSidebarForSize, flash;
    $document = $(document);
    $window = $(window);
    $body = $('body');
    gl.utils.preventDisabledButtons();
    bootstrapBreakpoint = bp.getBreakpointSize();
    $(".nav-sidebar").niceScroll({
      cursoropacitymax: '0.4',
      cursorcolor: '#FFF',
      cursorborder: "1px solid #FFF"
    });
    $(".js-select-on-focus").on("focusin", function() {
      return $(this).select().one('mouseup', function(e) {
        return e.preventDefault();
      });
    // Click a .js-select-on-focus field, select the contents
    // Prevent a mouseup event from deselecting the input
    });
    $('.remove-row').bind('ajax:success', function() {
      $(this).tooltip('destroy')
        .closest('li')
        .fadeOut();
    });
    $('.js-remove-tr').bind('ajax:before', function() {
      return $(this).hide();
    });
    $('.js-remove-tr').bind('ajax:success', function() {
      return $(this).closest('tr').fadeOut();
    });
    $('select.select2').select2({
      width: 'resolve',
      // Initialize select2 selects
      dropdownAutoWidth: true
    });
    $('.js-select2').bind('select2-close', function() {
      return setTimeout((function() {
        $('.select2-container-active').removeClass('select2-container-active');
        return $(':focus').blur();
      }), 1);
    // Close select2 on escape
    });
    // Initialize tooltips
    $body.tooltip({
      selector: '.has-tooltip, [data-toggle="tooltip"]',
      placement: function(_, el) {
        return $(el).data('placement') || 'bottom';
      }
    });
    $('.trigger-submit').on('change', function() {
      return $(this).parents('form').submit();
    // Form submitter
    });
    gl.utils.localTimeAgo($('abbr.timeago, .js-timeago'), true);
    // Flash
    if ((flash = $(".flash-container")).length > 0) {
      flash.click(function() {
        return $(this).fadeOut();
      });
      flash.show();
    }
    // Disable form buttons while a form is submitting
    $body.on('ajax:complete, ajax:beforeSend, submit', 'form', function(e) {
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
    $(document).ajaxError(function(e, xhrObj, xhrSetting, xhrErrorText) {
      var ref;
      if (xhrObj.status === 401) {
        return new Flash('You need to be logged in.', 'alert');
      } else if ((ref = xhrObj.status) === 404 || ref === 500) {
        return new Flash('Something went wrong on our end.', 'alert');
      }
    });
    $('.account-box').hover(function() {
      // Show/Hide the profile menu when hovering the account box
      return $(this).toggleClass('hover');
    });
    $document.on('click', '.diff-content .js-show-suppressed-diff', function() {
      var $container;
      $container = $(this).parent();
      $container.next('table').show();
      return $container.remove();
    // Commit show suppressed diff
    });
    $('.navbar-toggle').on('click', function() {
      $('.header-content .title').toggle();
      $('.header-content .header-logo').toggle();
      $('.header-content .navbar-collapse').toggle();
      return $('.navbar-toggle').toggleClass('active');
    });
    // Show/hide comments on diff
    $body.on("click", ".js-toggle-diff-comments", function(e) {
      var $this = $(this);
      $this.toggleClass('active');
      var notesHolders = $this.closest('.diff-file').find('.notes_holder');
      if ($this.hasClass('active')) {
        notesHolders.show().find('.hide').show();
      } else {
        notesHolders.hide();
      }
      $this.trigger('blur');
      return e.preventDefault();
    });
    $document.off("click", '.js-confirm-danger');
    $document.on("click", '.js-confirm-danger', function(e) {
      var btn, form, text;
      e.preventDefault();
      btn = $(e.target);
      text = btn.data("confirm-danger-message");
      form = btn.closest("form");
      return new ConfirmDangerModal(form, text);
    });
    $document.on('click', 'button', function() {
      return $(this).blur();
    });
    $('input[type="search"]').each(function() {
      var $this;
      $this = $(this);
      $this.attr('value', $this.val());
    });
    $document.off('keyup', 'input[type="search"]').on('keyup', 'input[type="search"]', function(e) {
      var $this;
      $this = $(this);
      return $this.attr('value', $this.val());
    });
    $sidebarGutterToggle = $('.js-sidebar-toggle');
    $document.off('breakpoint:change').on('breakpoint:change', function(e, breakpoint) {
      var $gutterIcon;
      if (breakpoint === 'sm' || breakpoint === 'xs') {
        $gutterIcon = $sidebarGutterToggle.find('i');
        if ($gutterIcon.hasClass('fa-angle-double-right')) {
          return $sidebarGutterToggle.trigger('click');
        }
      }
    });
    fitSidebarForSize = function() {
      var oldBootstrapBreakpoint;
      oldBootstrapBreakpoint = bootstrapBreakpoint;
      bootstrapBreakpoint = bp.getBreakpointSize();
      if (bootstrapBreakpoint !== oldBootstrapBreakpoint) {
        return $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
      }
    };
    checkInitialSidebarSize = function() {
      bootstrapBreakpoint = bp.getBreakpointSize();
      if (bootstrapBreakpoint === "xs" || "sm") {
        return $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
      }
    };
    $window.off("resize.app").on("resize.app", function(e) {
      return fitSidebarForSize();
    });
    gl.awardsHandler = new AwardsHandler();
    checkInitialSidebarSize();
    new Aside();

    // bind sidebar events
    new gl.Sidebar();

    // Custom time ago
    gl.utils.shortTimeAgo($('.js-short-timeago'));
  });
}).call(this);
