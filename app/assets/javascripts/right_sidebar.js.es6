/*= require lib/vue */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Sidebar = (function() {
    function Sidebar(currentUser) {
      this.toggleTodo = bind(this.toggleTodo, this);
      this.sidebar = $('aside.right-sidebar');
      this.addEventListeners();
      this.initVue()
    }

    Sidebar.prototype.addEventListeners = function() {
      this.sidebar.on('click', '.sidebar-collapsed-icon', this, this.sidebarCollapseClicked);
      $('.dropdown').on('hidden.gl.dropdown', this, this.onSidebarDropdownHidden);
      $('.dropdown').on('loading.gl.dropdown', this.sidebarDropdownLoading);
      $('.dropdown').on('loaded.gl.dropdown', this.sidebarDropdownLoaded);
      $(document).off('click', '.js-sidebar-toggle').on('click', '.js-sidebar-toggle', function(e, triggered) {
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
          return $.cookie("collapsed_gutter", $('.right-sidebar').hasClass('right-sidebar-collapsed'), {
            path: '/'
          });
        }
      });
      return $(document).off('click', '.js-issuable-todo').on('click', '.js-issuable-todo', this.toggleTodo);
    };

    Sidebar.prototype.toggleTodo = function(e) {
      var $btnText, $this, $todoLoading, ajaxType, url;
      $this = $(e.currentTarget);
      $todoLoading = $('.js-issuable-todo-loading');
      $btnText = $('.js-issuable-todo-text', $this);
      ajaxType = $this.attr('data-delete-path') ? 'DELETE' : 'POST';
      if ($this.attr('data-delete-path')) {
        url = "" + ($this.attr('data-delete-path'));
      } else {
        url = "" + ($this.data('url'));
      }
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
            return _this.beforeTodoSend($this, $todoLoading);
          };
        })(this)
      }).done((function(_this) {
        return function(data) {
          return _this.todoUpdateDone(data, $this, $btnText, $todoLoading);
        };
      })(this));
    };

    Sidebar.prototype.beforeTodoSend = function($btn, $todoLoading) {
      $btn.disable();
      return $todoLoading.removeClass('hidden');
    };

    Sidebar.prototype.todoUpdateDone = function(data, $btn, $btnText, $todoLoading) {
      var $todoPendingCount;
      $todoPendingCount = $('.todos-pending-count');
      $todoPendingCount.text(data.count);
      $btn.enable();
      $todoLoading.addClass('hidden');
      if (data.count === 0) {
        $todoPendingCount.addClass('hidden');
      } else {
        $todoPendingCount.removeClass('hidden');
      }
      if (data.delete_path != null) {
        $btn.attr('aria-label', $btn.data('mark-text')).attr('data-delete-path', data.delete_path);
        return $btnText.text($btn.data('mark-text'));
      } else {
        $btn.attr('aria-label', $btn.data('todo-text')).removeAttr('data-delete-path');
        return $btnText.text($btn.data('todo-text'));
      }
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

    Sidebar.prototype.isOpen = function() {
      return this.sidebar.is('.right-sidebar-expanded');
    };

    Sidebar.prototype.getBlock = function(name) {
      return this.sidebar.find(".block." + name);
    };

    Sidebar.prototype.initVue = function() {
      new Vue({
        el: this.sidebar.find('.lock-issue-block')[0],
        name: 'RightSidebarLockIssueBlock',
        data: { locked: false },
        methods: {
          toggleLock(e) {
            e.stopImmediatePropagation();
            this.locked = !this.locked;
          }
        }
      });
    };

    return Sidebar;

  })();

}).call(this);
