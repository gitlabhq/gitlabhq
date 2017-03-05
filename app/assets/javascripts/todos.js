/* eslint-disable class-methods-use-this, no-new, func-names, no-unneeded-ternary, object-shorthand, quote-props, no-param-reassign, max-len */
/* global UsersSelect */

((global) => {
  class Todos {
    constructor() {
      this.initFilters();
      this.bindEvents();

      this.cleanupWrapper = this.cleanup.bind(this);
      document.addEventListener('beforeunload', this.cleanupWrapper);
    }

    cleanup() {
      this.unbindEvents();
      document.removeEventListener('beforeunload', this.cleanupWrapper);
    }

    unbindEvents() {
      $('.js-done-todo, .js-undo-todo').off('click', this.updateStateClickedWrapper);
      $('.js-todos-mark-all').off('click', this.allDoneClickedWrapper);
      $('.todo').off('click', this.goToTodoUrl);
    }

    bindEvents() {
      this.updateStateClickedWrapper = this.updateStateClicked.bind(this);
      this.allDoneClickedWrapper = this.allDoneClicked.bind(this);

      $('.js-done-todo, .js-undo-todo').on('click', this.updateStateClickedWrapper);
      $('.js-todos-mark-all').on('click', this.allDoneClickedWrapper);
      $('.todo').on('click', this.goToTodoUrl);
    }

    initFilters() {
      new UsersSelect();
      this.initFilterDropdown($('.js-project-search'), 'project_id', ['text']);
      this.initFilterDropdown($('.js-type-search'), 'type');
      this.initFilterDropdown($('.js-action-search'), 'action_id');

      $('form.filter-form').on('submit', function (event) {
        event.preventDefault();
        gl.utils.visitUrl(`${this.action}&${$(this).serialize()}`);
      });
    }

    initFilterDropdown($dropdown, fieldName, searchFields) {
      $dropdown.glDropdown({
        fieldName,
        selectable: true,
        filterable: searchFields ? true : false,
        search: { fields: searchFields },
        data: $dropdown.data('data'),
        clicked: function () {
          return $dropdown.closest('form.filter-form').submit();
        },
      });
    }

    updateStateClicked(e) {
      e.preventDefault();
      const target = e.target;
      target.setAttribute('disabled', '');
      target.classList.add('disabled');
      $.ajax({
        type: 'POST',
        url: target.getAttribute('href'),
        dataType: 'json',
        data: {
          '_method': target.getAttribute('data-method'),
        },
        success: (data) => {
          this.updateState(target);
          this.updateBadges(data);
        },
      });
    }

    allDoneClicked(e) {
      e.preventDefault();
      const $target = $(e.currentTarget);
      $target.disable();
      $.ajax({
        type: 'POST',
        url: $target.attr('href'),
        dataType: 'json',
        data: {
          '_method': 'delete',
        },
        success: (data) => {
          $target.remove();
          $('.js-todos-all').html('<div class="nothing-here-block">You\'re all done!</div>');
          this.updateBadges(data);
        },
      });
    }

    updateState(target) {
      const row = target.closest('li');
      const restoreBtn = row.querySelector('.js-undo-todo');
      const doneBtn = row.querySelector('.js-done-todo');

      target.removeAttribute('disabled');
      target.classList.remove('disabled');
      target.classList.add('hidden');

      if (target === doneBtn) {
        row.classList.add('done-reversible');
        restoreBtn.classList.remove('hidden');
      } else {
        row.classList.remove('done-reversible');
        doneBtn.classList.remove('hidden');
      }
    }

    updateBadges(data) {
      $(document).trigger('todo:toggle', data.count);
      $('.todos-pending .badge').text(data.count);
      $('.todos-done .badge').text(data.done_count);
    }

    goToTodoUrl(e) {
      const todoLink = this.dataset.url;

      if (!todoLink) {
        return;
      }

      if (gl.utils.isMetaClick(e)) {
        const windowTarget = '_blank';
        const selected = e.target;
        e.preventDefault();

        if (selected.tagName === 'IMG') {
          const avatarUrl = selected.parentElement.getAttribute('href');
          window.open(avatarUrl, windowTarget);
        } else {
          window.open(todoLink, windowTarget);
        }
      } else {
        gl.utils.visitUrl(todoLink);
      }
    }
  }

  global.Todos = Todos;
})(window.gl || (window.gl = {}));
