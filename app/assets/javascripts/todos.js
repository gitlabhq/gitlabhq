/* eslint-disable class-methods-use-this, no-unneeded-ternary, quote-props */

import UsersSelect from './users_select';

export default class Todos {
  constructor() {
    this.initFilters();
    this.bindEvents();
    this.todo_ids = [];

    this.cleanupWrapper = this.cleanup.bind(this);
    document.addEventListener('beforeunload', this.cleanupWrapper);
  }

  cleanup() {
    this.unbindEvents();
    document.removeEventListener('beforeunload', this.cleanupWrapper);
  }

  unbindEvents() {
    $('.js-done-todo, .js-undo-todo, .js-add-todo').off('click', this.updateRowStateClickedWrapper);
    $('.js-todos-mark-all', '.js-todos-undo-all').off('click', this.updateallStateClickedWrapper);
    $('.todo').off('click', this.goToTodoUrl);
  }

  bindEvents() {
    this.updateRowStateClickedWrapper = this.updateRowStateClicked.bind(this);
    this.updateAllStateClickedWrapper = this.updateAllStateClicked.bind(this);

    $('.js-done-todo, .js-undo-todo, .js-add-todo').on('click', this.updateRowStateClickedWrapper);
    $('.js-todos-mark-all, .js-todos-undo-all').on('click', this.updateAllStateClickedWrapper);
    $('.todo').on('click', this.goToTodoUrl);
  }

  initFilters() {
    this.initFilterDropdown($('.js-project-search'), 'project_id', ['text']);
    this.initFilterDropdown($('.js-type-search'), 'type');
    this.initFilterDropdown($('.js-action-search'), 'action_id');

    $('form.filter-form').on('submit', function applyFilters(event) {
      event.preventDefault();
      gl.utils.visitUrl(`${this.action}&${$(this).serialize()}`);
    });
    return new UsersSelect();
  }

  initFilterDropdown($dropdown, fieldName, searchFields) {
    $dropdown.glDropdown({
      fieldName,
      selectable: true,
      filterable: searchFields ? true : false,
      search: { fields: searchFields },
      data: $dropdown.data('data'),
      clicked: () => $dropdown.closest('form.filter-form').submit(),
    });
  }

  updateRowStateClicked(e) {
    e.preventDefault();

    const target = e.target;
    target.setAttribute('disabled', true);
    target.classList.add('disabled');
    $.ajax({
      type: 'POST',
      url: target.dataset.href,
      dataType: 'json',
      data: {
        '_method': target.dataset.method,
      },
      success: (data) => {
        this.updateRowState(target);
        return this.updateBadges(data);
      },
    });
  }

  updateRowState(target) {
    const row = target.closest('li');
    const restoreBtn = row.querySelector('.js-undo-todo');
    const doneBtn = row.querySelector('.js-done-todo');

    target.classList.add('hidden');
    target.removeAttribute('disabled');
    target.classList.remove('disabled');

    if (target === doneBtn) {
      row.classList.add('done-reversible');
      restoreBtn.classList.remove('hidden');
    } else if (target === restoreBtn) {
      row.classList.remove('done-reversible');
      doneBtn.classList.remove('hidden');
    } else {
      row.parentNode.removeChild(row);
    }
  }

  updateAllStateClicked(e) {
    e.preventDefault();

    const target = e.currentTarget;
    const requestData = { '_method': target.dataset.method, ids: this.todo_ids };
    target.setAttribute('disabled', true);
    target.classList.add('disabled');
    $.ajax({
      type: 'POST',
      url: target.dataset.href,
      dataType: 'json',
      data: requestData,
      success: (data) => {
        this.updateAllState(target, data);
        return this.updateBadges(data);
      },
    });
  }

  updateAllState(target, data) {
    const markAllDoneBtn = document.querySelector('.js-todos-mark-all');
    const undoAllBtn = document.querySelector('.js-todos-undo-all');
    const todoListContainer = document.querySelector('.js-todos-list-container');
    const nothingHereContainer = document.querySelector('.js-nothing-here-container');

    target.removeAttribute('disabled');
    target.classList.remove('disabled');

    this.todo_ids = (target === markAllDoneBtn) ? data.updated_ids : [];
    undoAllBtn.classList.toggle('hidden');
    markAllDoneBtn.classList.toggle('hidden');
    todoListContainer.classList.toggle('hidden');
    nothingHereContainer.classList.toggle('hidden');
  }

  updateBadges(data) {
    $(document).trigger('todo:toggle', data.count);
    document.querySelector('.todos-pending .badge').innerHTML = data.count;
    document.querySelector('.todos-done .badge').innerHTML = data.done_count;
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
