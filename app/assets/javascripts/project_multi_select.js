import $ from 'jquery';
import _ from 'underscore';
import Api from './api';
import { renderAvatar } from './helpers/avatar_helper';

const PER_PAGE = 10;

function renderProjectItem(project) {
  const projectTitle = project.name_with_namespace || project.name;

  return (
`<div class="frequent-items-list-item-container d-flex">
  <div class="frequent-items-item-avatar-container">
    ${renderAvatar(project, { sizeClass: 's32' })}
  </div>
  <div class="frequent-items-item-metadata-container">
    <div title="${_.escape(projectTitle)}" class="frequent-items-item-title">${_.escape(projectTitle)}</div>
    <div title="${_.escape(project.description)}" class="frequent-items-item-namespace">${_.escape(project.description)}</div>
  </div>
</div>`
  );
}

function renderProjectSelection(project) {
  const projectTitle = project.name_with_namespace || project.name;

  return (
`<div class="frequent-items-list-item-container d-flex">
  <div class="frequent-items-item-avatar-container">
    ${renderAvatar(project, { sizeClass: 's16' })}
  </div>
  <div title="${_.escape(projectTitle)}" class="frequent-items-item-title">${_.escape(projectTitle)}</div>
</div>`
  );
}

function createQuery(queryOptions) {
  return ({ term, callback, page }) => Api.projects(term, { ...queryOptions, page })
    .then(results => ({
      results,
      more: results.length === PER_PAGE,
    }))
    .then(callback);
}

function mapIdsToProjects(val) {
  if (!val) {
    return Promise.resolve([]);
  }

  const ids = Array.isArray(val) ? val : [val];
  const reqs = ids.map(id => Api.project(id)
    .then(x => x.data)
    .catch(() => null));

  return Promise.all(reqs).then(projs => projs.filter(x => x));
}

/**
 * Add the input icon which is toggled on/off when select2 is loading
 *
 * This prevents collision with select2's spinner
 *
 * @param {JQuery} $select
 */
function setupSelect2IconEvents($select) {
  const $iconContainer = $select.select2('container')
    .parents('.input-icon-wrapper')
    .first();

  $select.on('select2-opening', () => {
    $iconContainer.addClass('hide-input-icon');
  });

  $select.on('select2-close', () => {
    $iconContainer.removeClass('hide-input-icon');
  });
}

function setupProjectMultiSelect(select) {
  const $select = $(select);

  const queryOptions = {
    order_by: $select.data('orderBy') || 'id',
    per_page: PER_PAGE,
  };

  $select.select2({
    query: createQuery(queryOptions),
    minimumInputLength: 0,
    multiple: true,
    closeOnSelect: false,
    dropdownCssClass: 'project-multi-select-dropdown',
    placeholder: 'All Projects',
    formatResult: renderProjectItem,
    formatSelection: renderProjectSelection,
    initSelection: (element, callback) => mapIdsToProjects($select.select2('val')).then(callback),
    id: x => x.id,
  });

  $select.val([]);

  setupSelect2IconEvents($select);

  return select;
}

export default function projectMultiSelect() {
  $('.js-project-multi-select').each((i, select) => setupProjectMultiSelect(select));
}
