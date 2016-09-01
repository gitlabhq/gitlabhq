(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Todos = (function() {
    function Todos(opts) {
      var ref;
      if (opts == null) {
        opts = {};
      }
      this.allDoneClicked = bind(this.allDoneClicked, this);
      this.doneClicked = bind(this.doneClicked, this);
      this.el = (ref = opts.el) != null ? ref : $('.js-todos-options');
      this.perPage = this.el.data('perPage');
      this.clearListeners();
      this.initBtnListeners();
      this.initFilters();
    }

    Todos.prototype.clearListeners = function() {
      $('.done-todo').off('click');
      $('.js-todos-mark-all').off('click');
      return $('.todo').off('click');
    };

    Todos.prototype.initBtnListeners = function() {
      $('.done-todo').on('click', this.doneClicked);
      $('.js-todos-mark-all').on('click', this.allDoneClicked);
      return $('.todo').on('click', this.goToTodoUrl);
    };

    Todos.prototype.initFilters = function() {
      new UsersSelect();
      this.initFilterDropdown($('.js-project-search'), 'project_id', ['text']);
      this.initFilterDropdown($('.js-type-search'), 'type');
      this.initFilterDropdown($('.js-action-search'), 'action_id');

      $('form.filter-form').on('submit', function (event) {
        event.preventDefault();
        Turbolinks.visit(this.action + '&' + $(this).serialize());
      });
    };

    Todos.prototype.initFilterDropdown = function($dropdown, fieldName, searchFields) {
      $dropdown.glDropdown({
        selectable: true,
        filterable: searchFields ? true : false,
        fieldName: fieldName,
        search: { fields: searchFields },
        data: $dropdown.data('data'),
        clicked: function() {
          return $dropdown.closest('form.filter-form').submit();
        }
      })
    };

    Todos.prototype.doneClicked = function(e) {
      var $this;
      e.preventDefault();
      e.stopImmediatePropagation();
      $this = $(e.currentTarget);
      $this.disable();
      return $.ajax({
        type: 'POST',
        url: $this.attr('href'),
        dataType: 'json',
        data: {
          '_method': 'delete'
        },
        success: (function(_this) {
          return function(data) {
            _this.redirectIfNeeded(data.count);
            _this.clearDone($this.closest('li'));
            return _this.updateBadges(data);
          };
        })(this)
      });
    };

    Todos.prototype.allDoneClicked = function(e) {
      var $this;
      e.preventDefault();
      e.stopImmediatePropagation();
      $this = $(e.currentTarget);
      $this.disable();
      return $.ajax({
        type: 'POST',
        url: $this.attr('href'),
        dataType: 'json',
        data: {
          '_method': 'delete'
        },
        success: (function(_this) {
          return function(data) {
            $this.remove();
            $('.prepend-top-default').html('<div class="nothing-here-block">You\'re all done!</div>');
            return _this.updateBadges(data);
          };
        })(this)
      });
    };

    Todos.prototype.clearDone = function($row) {
      var $ul;
      $ul = $row.closest('ul');
      $row.remove();
      if (!$ul.find('li').length) {
        return $ul.parents('.panel').remove();
      }
    };

    Todos.prototype.updateBadges = function(data) {
      $('.todos-pending .badge, .todos-pending-count').text(data.count);
      return $('.todos-done .badge').text(data.done_count);
    };

    Todos.prototype.getTotalPages = function() {
      return this.el.data('totalPages');
    };

    Todos.prototype.getCurrentPage = function() {
      return this.el.data('currentPage');
    };

    Todos.prototype.getTodosPerPage = function() {
      return this.el.data('perPage');
    };

    Todos.prototype.redirectIfNeeded = function(total) {
      var currPage, currPages, newPages, pageParams, url;
      currPages = this.getTotalPages();
      currPage = this.getCurrentPage();
      if (!total) {
        location.reload();
        return;
      }
      if (!currPages) {
        return;
      }
      newPages = Math.ceil(total / this.getTodosPerPage());
      url = location.href;
      if (newPages !== currPages) {
        if (currPages > 1 && currPage === currPages) {
          pageParams = {
            page: currPages - 1
          };
          url = gl.utils.mergeUrlParams(pageParams, url);
        }
        return Turbolinks.visit(url);
      }
    };

    Todos.prototype.goToTodoUrl = function(e) {
      var todoLink;
      todoLink = $(this).data('url');
      if (!todoLink) {
        return;
      }
      if (e.metaKey || e.which === 2) {
        e.preventDefault();
        return window.open(todoLink, '_blank');
      } else {
        return Turbolinks.visit(todoLink);
      }
    };

    return Todos;

  })();

}).call(this);
