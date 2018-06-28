import $ from 'jquery';
import _ from 'underscore';
import Api from './api';
import { renderAvatar } from './helpers/avatar_helper';

const ALL_PROJECTS_ITEM = {
  id: 'all',
  name: 'All Projects',
};

export function getDecoratedId(proj, isSelected) {
  return `${isSelected ? 'SELECTED-' : ''}(${proj.id})`;
}

export function parseDecoratedId(str) {
  return {
    id: str.match(/[(](.*)[)]$/)[1],
    isSelected: !!str.match(/^SELECTED/),
  };
}

function isAllProjectsItem(proj) {
  return proj.id === ALL_PROJECTS_ITEM.id;
}

function renderProjectItem(project, isSelected) {
  const projectTitle = project.name_with_namespace || project.name;
  const isAll = isAllProjectsItem(project);
  const classes = [
    isSelected ? 'is-active' : '',
    isAll ? 'project-multi-select-all' : '',
  ].filter(x => x).join(' ');

  return (
`<div class="dropdown-menu-item label-item ${classes}">
  <div class="projects-list-item-container clearfix">
    <div class="project-item-avatar-container">
      ${renderAvatar(project)}
    </div>
    <div class="project-item-metadata-container">
      <div title="${_.escape(projectTitle)}" class="project-title">${_.escape(projectTitle)}</div>
      <div title="${_.escape(project.description)}" class="project-namespace">${_.escape(project.description)}</div>
    </div>
  </div>
</div>`
  );
}

function renderProjectSelection(project) {
  const projectTitle = project.name_with_namespace || project.name;

  return (
`<div class="project-inline-container">
  <div class="project-item-avatar-container">
    ${renderAvatar(project, { sizeClass: 's16' })}
  </div>
  <div title="${_.escape(projectTitle)}" class="project-title">${_.escape(projectTitle)}</div> 
</div>`
  );
}

function prependAllProjectsItem(projects) {
  return [ALL_PROJECTS_ITEM].concat(projects);
}

function createQuerier(queryOptions) {
  return ({ term, callback }) => Api.projects(term, queryOptions)
    .then(prependAllProjectsItem)
    .then(results => ({
      results,
    }))
    .then(callback);
}

function setupMultiProjectSelect(select) {
  const $select = $(select);

  const queryOptions = {
    order_by: $select.data('orderBy') || 'id',
  };

  const getCurrentVal = () => $select.select2('val');
  const isSelected = proj => {
    if (isAllProjectsItem(proj)) {
      return getCurrentVal().length === 0;
    }

    return getCurrentVal().indexOf(getDecoratedId(proj)) >= 0;
  };

  $select.select2({
    query: createQuerier(queryOptions),
    multiple: true,
    closeOnSelect: false,
    text: null,
    dropdownCssClass: 'project-multi-select-dropdown dropdown-menu-selectable',
    containerCssClass: 'project-multi-select-dropdown',
    placeholder: ALL_PROJECTS_ITEM.name,
    formatResult(proj) {
      return renderProjectItem(proj, isSelected(proj));
    },
    formatSelection(proj) {
      return renderProjectSelection(proj);
    },
    id(proj) {
      return getDecoratedId(proj, isSelected(proj));
    },
  });

  $select.val([]);

  $select.on('select2-selecting', (e) => {
    const proj = parseDecoratedId(e.val);

    if (proj.isSelected) {
      e.preventDefault();
    } else if (isAllProjectsItem(proj)) {
      e.preventDefault();
      $select.select2('val', '');
      // we need to refresh select2 view or removed item's don't refresh.
      $select.select2('search', '');
    }
  });

  $select.on('select2-removing', e => {
    const delId = parseDecoratedId(e.val).id;
    const newVal = getCurrentVal().filter(x => parseDecoratedId(x).id !== delId);

    $select.val(newVal, true);
  });

  return select;
}

export default function multiProjectSelect() {
  $('.ajax-project-select').each((i, select) => setupMultiProjectSelect(select));
}
