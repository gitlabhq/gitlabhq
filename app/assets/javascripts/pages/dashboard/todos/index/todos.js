/* eslint-disable class-methods-use-this */

import $ from 'jquery';
import { getGroups } from '~/api/groups_api';
import { getProjects } from '~/api/projects_api';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { isMetaClick } from '~/lib/utils/common_utils';
import { addDelimiter } from '~/lib/utils/text_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import UsersSelect from '~/users_select';

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
    document.querySelectorAll('.js-done-todo, .js-undo-todo, .js-add-todo').forEach((el) => {
      el.removeEventListener('click', this.updateRowStateClickedWrapper);
    });
    document.querySelectorAll('.js-todos-mark-all, .js-todos-undo-all').forEach((el) => {
      el.removeEventListener('click', this.updateallStateClickedWrapper);
    });
    document.querySelectorAll('.todo').forEach((el) => {
      el.removeEventListener('click', this.goToTodoUrl);
      el.removeEventListener('auxclick', this.goToTodoUrl);
    });
  }

  bindEvents() {
    this.updateRowStateClickedWrapper = this.updateRowStateClicked.bind(this);
    this.updateAllStateClickedWrapper = this.updateAllStateClicked.bind(this);

    document.querySelectorAll('.js-done-todo, .js-undo-todo, .js-add-todo').forEach((el) => {
      el.addEventListener('click', this.updateRowStateClickedWrapper);
    });
    document.querySelectorAll('.js-todos-mark-all, .js-todos-undo-all').forEach((el) => {
      el.addEventListener('click', this.updateAllStateClickedWrapper);
    });
    document.querySelectorAll('.todo').forEach((el) => {
      el.addEventListener('click', this.goToTodoUrl);
      el.addEventListener('auxclick', this.goToTodoUrl);
    });
  }

  initFilters() {
    this.initAjaxFilterDropdown(getGroups, $('.js-group-search'), 'group_id');
    this.initAjaxFilterDropdown(getProjects, $('.js-project-search'), 'project_id');
    this.initFilterDropdown($('.js-type-search'), 'type');
    this.initFilterDropdown($('.js-action-search'), 'action_id');

    return new UsersSelect();
  }

  initAjaxFilterDropdown(apiMethod, $dropdown, fieldName) {
    initDeprecatedJQueryDropdown($dropdown, {
      fieldName,
      selectable: true,
      filterable: true,
      filterRemote: true,
      data(search, callback) {
        return apiMethod(search, {}, (data) => {
          callback(
            data.map((d) => ({
              id: d.id,
              text: d.full_name || d.name_with_namespace,
            })),
          );
        });
      },
      clicked: () => {
        const $formEl = $dropdown.closest('form.filter-form');
        $formEl.submit();
      },
    });
  }

  initFilterDropdown($dropdown, fieldName, searchFields) {
    initDeprecatedJQueryDropdown($dropdown, {
      fieldName,
      selectable: true,
      filterable: Boolean(searchFields),
      search: { fields: searchFields },
      data: $dropdown.data('data'),
      clicked: () => {
        const $formEl = $dropdown.closest('form.filter-form');
        $formEl.submit();
      },
    });
  }

  updateRowStateClicked(e) {
    e.stopPropagation();
    e.preventDefault();

    const { target } = e;
    target.setAttribute('disabled', true);
    target.classList.add('disabled');

    target.querySelector('.gl-spinner-container').classList.add('gl-mr-2');

    axios[target.dataset.method](target.dataset.href)
      .then(({ data }) => {
        this.updateRowState(target);
        this.updateBadges(data);
      })
      .catch(() => {
        this.updateRowState(target, true);
        return createFlash({
          message: __('Error updating status of to-do item.'),
        });
      });
  }

  updateRowState(target, isInactive = false) {
    const row = target.closest('li');
    const restoreBtn = row.querySelector('.js-undo-todo');
    const doneBtn = row.querySelector('.js-done-todo');

    target.classList.add('hidden');
    target.removeAttribute('disabled');
    target.classList.remove('disabled');

    target.querySelector('.gl-spinner-container').classList.remove('gl-mr-2');

    if (isInactive === true) {
      restoreBtn.classList.add('hidden');
      doneBtn.classList.remove('hidden');
    } else if (target === doneBtn) {
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
    e.stopPropagation();
    e.preventDefault();

    const target = e.currentTarget;
    target.setAttribute('disabled', true);
    target.classList.add('disabled');

    target.querySelector('.gl-spinner-container').classList.add('gl-mr-2');

    axios[target.dataset.method](target.dataset.href, {
      ids: this.todo_ids,
    })
      .then(({ data }) => {
        this.updateAllState(target, data);
        this.updateBadges(data);
      })
      .catch(() =>
        createFlash({
          message: __('Error updating status for all to-do items.'),
        }),
      );
  }

  updateAllState(target, data) {
    const markAllDoneBtn = document.querySelector('.js-todos-mark-all');
    const undoAllBtn = document.querySelector('.js-todos-undo-all');
    const todoListContainer = document.querySelector('.js-todos-list-container');
    const nothingHereContainer = document.querySelector('.js-nothing-here-container');

    target.removeAttribute('disabled');
    target.classList.remove('disabled');

    target.querySelector('.gl-spinner-container').classList.remove('gl-mr-2');

    this.todo_ids = target === markAllDoneBtn ? data.updated_ids : [];
    undoAllBtn.classList.toggle('hidden');
    markAllDoneBtn.classList.toggle('hidden');
    todoListContainer.classList.toggle('hidden');
    nothingHereContainer.classList.toggle('hidden');
  }

  updateBadges(data) {
    const event = new CustomEvent('todo:toggle', {
      detail: {
        count: data.count,
      },
    });

    document.dispatchEvent(event);
    document.querySelector('.js-todos-pending .js-todos-badge').innerHTML = addDelimiter(
      data.count,
    );
    document.querySelector('.js-todos-done .js-todos-badge').innerHTML = addDelimiter(
      data.done_count,
    );
  }

  goToTodoUrl(e) {
    const todoLink = this.dataset.url;

    if (!todoLink || e.target.closest('a')) {
      return;
    }

    e.stopPropagation();
    e.preventDefault();

    const isPrimaryClick = e.button === 0;

    if (isMetaClick(e)) {
      const windowTarget = '_blank';

      window.open(todoLink, windowTarget);
    } else if (isPrimaryClick) {
      visitUrl(todoLink);
    }
  }
}
