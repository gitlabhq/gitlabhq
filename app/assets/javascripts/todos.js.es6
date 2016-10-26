/* eslint-disable */
((global) => {

  class Todos {
    constructor({ el } = {}) {
      this.allDoneClicked = this.allDoneClicked.bind(this);
      this.doneClicked = this.doneClicked.bind(this);
      this.el = el || $('.js-todos-options');
      this.perPage = this.el.data('perPage');
      this.clearListeners();
      this.initBtnListeners();
      this.initFilters();
    }

    clearListeners() {
      $('.done-todo').off('click');
      $('.js-todos-mark-all').off('click');
      return $('.todo').off('click');
    }

    initBtnListeners() {
      $('.done-todo').on('click', this.doneClicked);
      $('.js-todos-mark-all').on('click', this.allDoneClicked);
      return $('.todo').on('click', this.goToTodoUrl);
    }

    initFilters() {
      new UsersSelect();
      this.initFilterDropdown($('.js-project-search'), 'project_id', ['text']);
      this.initFilterDropdown($('.js-type-search'), 'type');
      this.initFilterDropdown($('.js-action-search'), 'action_id');

      $('form.filter-form').on('submit', function (event) {
        event.preventDefault();
        Turbolinks.visit(this.action + '&' + $(this).serialize());
      });
    }

    initFilterDropdown($dropdown, fieldName, searchFields) {
      $dropdown.glDropdown({
        fieldName,
        selectable: true,
        filterable: searchFields ? true : false,
        search: { fields: searchFields },
        data: $dropdown.data('data'),
        clicked: function() {
          return $dropdown.closest('form.filter-form').submit();
        }
      })
    }

    doneClicked(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      const $target = $(e.currentTarget);
      $target.disable();
      return $.ajax({
        type: 'POST',
        url: $target.attr('href'),
        dataType: 'json',
        data: {
          '_method': 'delete'
        },
        success: (data) => {
          this.redirectIfNeeded(data.count);
          this.clearDone($target.closest('li'));
          return this.updateBadges(data);
        }
      });
    }

    allDoneClicked(e) {
      e.preventDefault();
      e.stopImmediatePropagation();
      $target = $(e.currentTarget);
      $target.disable();
      return $.ajax({
        type: 'POST',
        url: $target.attr('href'),
        dataType: 'json',
        data: {
          '_method': 'delete'
        },
        success: (data) => {
          $target.remove();
          $('.prepend-top-default').html('<div class="nothing-here-block">You\'re all done!</div>');
          return this.updateBadges(data);
        }
      });
    }

    clearDone($row) {
      const $ul = $row.closest('ul');
      $row.remove();
      if (!$ul.find('li').length) {
        return $ul.parents('.panel').remove();
      }
    }

    updateBadges(data) {
      $('.todos-pending .badge, .todos-pending-count').text(data.count);
      return $('.todos-done .badge').text(data.done_count);
    }

    getTotalPages() {
      return this.el.data('totalPages');
    }

    getCurrentPage() {
      return this.el.data('currentPage');
    }

    getTodosPerPage() {
      return this.el.data('perPage');
    }

    redirectIfNeeded(total) {
      const currPages = this.getTotalPages();
      const currPage = this.getCurrentPage();

      // Refresh if no remaining Todos
      if (!total) {
        window.location.reload();
        return;
      }
      // Do nothing if no pagination
      if (!currPages) {
        return;
      }

      const newPages = Math.ceil(total / this.getTodosPerPage());
      let url = location.href;

      if (newPages !== currPages) {
        // Redirect to previous page if there's one available
        if (currPages > 1 && currPage === currPages) {
          const pageParams = {
            page: currPages - 1
          };
          url = gl.utils.mergeUrlParams(pageParams, url);
        }
        return Turbolinks.visit(url);
      }
    }

    goToTodoUrl(e) {
      const todoLink = $(this).data('url');
      if (!todoLink) {
        return;
      }
      // Allow Meta-Click or Mouse3-click to open in a new tab
      if (e.metaKey || e.which === 2) {
        e.preventDefault();
        return window.open(todoLink, '_blank');
      } else {
        return Turbolinks.visit(todoLink);
      }
    }
  }

  global.Todos = Todos;
})(window.gl || (window.gl = {}));
