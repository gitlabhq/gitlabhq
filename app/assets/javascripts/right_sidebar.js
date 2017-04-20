/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-unused-vars, consistent-return, one-var, one-var-declaration-per-line, quotes, prefer-template, object-shorthand, comma-dangle, no-else-return, no-param-reassign, max-len */

import Cookies from 'js-cookie';

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

  this.Sidebar = (function() {
    function Sidebar(currentUser) {
      this.toggleTodo = bind(this.toggleTodo, this);
      this.window = window;
      this.sidebar = $('aside');
      this.navBar = document.querySelector('.navbar-gitlab');
      this.layoutNav = document.querySelector('.layout-nav');
      this.rightSidebar = document.querySelector('.js-right-sidebar');
      this.navHeight = this.navBar.clientHeight + this.layoutNav.clientHeight + 1;
      this.setSidebarHeight();
      this.removeListeners();
      this.addEventListeners();
    }

    Sidebar.prototype.removeListeners = function () {
      this.sidebar.off('click', '.sidebar-collapsed-icon');
      $('.dropdown').off('hidden.gl.dropdown');
      $('.dropdown').off('loading.gl.dropdown');
      $('.dropdown').off('loaded.gl.dropdown');
      $(document).off('click', '.js-sidebar-toggle');
    };

    Sidebar.prototype.addEventListeners = function() {
      const $document = $(document);
      const throttledSetSidebarHeight = this.setSidebarHeight.bind(this);

      this.sidebar.on('click', '.sidebar-collapsed-icon', this, this.sidebarCollapseClicked);
      $('.dropdown').on('hidden.gl.dropdown', this, this.onSidebarDropdownHidden);
      $('.dropdown').on('loading.gl.dropdown', this.sidebarDropdownLoading);
      $('.dropdown').on('loaded.gl.dropdown', this.sidebarDropdownLoaded);
      $(window).on('resize', () => throttledSetSidebarHeight());
      $document.on('scroll', () => throttledSetSidebarHeight());
      $document.on('click', '.js-sidebar-toggle', function(e, triggered) {
        var $allGutterToggleIcons, $this, $thisIcon;
        e.preventDefault();
        $this = $(this);
        $thisIcon = $this.find('i');
        $allGutterToggleIcons = $('.js-sidebar-toggle i');
        if ($thisIcon.hasClass('fa-angle-double-right')) {
          $allGutterToggleIcons.removeClass('fa-angle-double-right').addClass('fa-angle-double-left');
          $('aside.right-sidebar').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
          $('.page-with-sidebar').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
        } else {
          $allGutterToggleIcons.removeClass('fa-angle-double-left').addClass('fa-angle-double-right');
          $('aside.right-sidebar').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');
          $('.page-with-sidebar').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');
        }
        if (!triggered) {
          return Cookies.set("collapsed_gutter", $('.right-sidebar').hasClass('right-sidebar-collapsed'));
        }
      });
      return $(document).off('click', '.js-issuable-todo').on('click', '.js-issuable-todo', this.toggleTodo);
    };

    Sidebar.prototype.toggleTodo = function(e) {
      var $btnText, $this, $todoLoading, ajaxType, url;
      $this = $(e.currentTarget);
      ajaxType = $this.attr('data-delete-path') ? 'DELETE' : 'POST';
      if ($this.attr('data-delete-path')) {
        url = "" + ($this.attr('data-delete-path'));
      } else {
        url = "" + ($this.data('url'));
      }

      $this.tooltip('hide');

      return $.ajax({
        url: url,
        type: ajaxType,
        dataType: 'json',
        data: {
          issuable_id: $this.data('issuable-id'),
          issuable_type: $this.data('issuable-type')
        },
        beforeSend: (function(_this) {
          return function() {
            $('.js-issuable-todo').disable()
              .addClass('is-loading');
          };
        })(this)
      }).done((function(_this) {
        return function(data) {
          return _this.todoUpdateDone(data);
        };
      })(this));
    };

    Sidebar.prototype.todoUpdateDone = function(data) {
      const deletePath = data.delete_path ? data.delete_path : null;
      const attrPrefix = deletePath ? 'mark' : 'todo';
      const $todoBtns = $('.js-issuable-todo');

      $(document).trigger('todo:toggle', data.count);

      $todoBtns.each((i, el) => {
        const $el = $(el);
        const $elText = $el.find('.js-issuable-todo-inner');

        $el.removeClass('is-loading')
          .enable()
          .attr('aria-label', $el.data(`${attrPrefix}-text`))
          .attr('data-delete-path', deletePath)
          .attr('title', $el.data(`${attrPrefix}-text`));

        if ($el.hasClass('has-tooltip')) {
          $el.tooltip('fixTitle');
        }

        if ($el.data(`${attrPrefix}-icon`)) {
          $elText.html($el.data(`${attrPrefix}-icon`));
        } else {
          $elText.text($el.data(`${attrPrefix}-text`));
        }
      });
    };

    Sidebar.prototype.sidebarDropdownLoading = function(e) {
      var $loading, $sidebarCollapsedIcon, i, img;
      $sidebarCollapsedIcon = $(this).closest('.block').find('.sidebar-collapsed-icon');
      img = $sidebarCollapsedIcon.find('img');
      i = $sidebarCollapsedIcon.find('i');
      $loading = $('<i class="fa fa-spinner fa-spin"></i>');
      if (img.length) {
        img.before($loading);
        return img.hide();
      } else if (i.length) {
        i.before($loading);
        return i.hide();
      }
    };

    Sidebar.prototype.sidebarDropdownLoaded = function(e) {
      var $sidebarCollapsedIcon, i, img;
      $sidebarCollapsedIcon = $(this).closest('.block').find('.sidebar-collapsed-icon');
      img = $sidebarCollapsedIcon.find('img');
      $sidebarCollapsedIcon.find('i.fa-spin').remove();
      i = $sidebarCollapsedIcon.find('i');
      if (img.length) {
        return img.show();
      } else {
        return i.show();
      }
    };

    Sidebar.prototype.sidebarCollapseClicked = function(e) {
      var $block, sidebar;
      if ($(e.currentTarget).hasClass('dont-change-state')) {
        return;
      }
      sidebar = e.data;
      e.preventDefault();
      $block = $(this).closest('.block');
      return sidebar.openDropdown($block);
    };

    Sidebar.prototype.openDropdown = function(blockOrName) {
      var $block;
      $block = _.isString(blockOrName) ? this.getBlock(blockOrName) : blockOrName;
      $block.find('.edit-link').trigger('click');
      if (!this.isOpen()) {
        this.setCollapseAfterUpdate($block);
        return this.toggleSidebar('open');
      }
    };

    Sidebar.prototype.setCollapseAfterUpdate = function($block) {
      $block.addClass('collapse-after-update');
      return $('.page-with-sidebar').addClass('with-overlay');
    };

    Sidebar.prototype.onSidebarDropdownHidden = function(e) {
      var $block, sidebar;
      sidebar = e.data;
      e.preventDefault();
      $block = $(this).closest('.block');
      return sidebar.sidebarDropdownHidden($block);
    };

    Sidebar.prototype.sidebarDropdownHidden = function($block) {
      if ($block.hasClass('collapse-after-update')) {
        $block.removeClass('collapse-after-update');
        $('.page-with-sidebar').removeClass('with-overlay');
        return this.toggleSidebar('hide');
      }
    };

    Sidebar.prototype.triggerOpenSidebar = function() {
      return this.sidebar.find('.js-sidebar-toggle').trigger('click');
    };

    Sidebar.prototype.toggleSidebar = function(action) {
      if (action == null) {
        action = 'toggle';
      }
      if (action === 'toggle') {
        this.triggerOpenSidebar();
      }
      if (action === 'open') {
        if (!this.isOpen()) {
          this.triggerOpenSidebar();
        }
      }
      if (action === 'hide') {
        if (this.isOpen()) {
          return this.triggerOpenSidebar();
        }
      }
    };

    Sidebar.prototype.setSidebarHeight = function() {
      let diff = this.navHeight - this.window.scrollY;
      diff = diff < 0 ? 0 : diff;

      this.rightSidebar.style.transform = `translateY(${diff}px)`;
    };

    Sidebar.prototype.isOpen = function() {
      return this.sidebar.is('.right-sidebar-expanded');
    };

    Sidebar.prototype.getBlock = function(name) {
      return this.sidebar.find(".block." + name);
    };

    return Sidebar;
  })();
}).call(window);
