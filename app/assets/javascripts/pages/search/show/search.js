import $ from 'jquery';
import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { deprecatedCreateFlash as Flash } from '~/flash';
import Api from '~/api';
import { __ } from '~/locale';
import Project from '~/pages/projects/project';
import { visitUrl, queryToObject } from '~/lib/utils/url_utility';
import refreshCounts from './refresh_counts';

export default class Search {
  constructor() {
    setHighlightClass(); // Code Highlighting
    const $projectDropdown = $('.js-search-project-dropdown');

    this.searchInput = '.js-search-input';
    this.searchClear = '.js-search-clear';

    const query = queryToObject(window.location.search);
    this.groupId = query?.group_id;
    this.eventListeners();
    refreshCounts();

    initDeprecatedJQueryDropdown($projectDropdown, {
      selectable: true,
      filterable: true,
      filterRemote: true,
      fieldName: 'project_id',
      search: {
        fields: ['name'],
      },
      data: (term, callback) => {
        this.getProjectsData(term)
          .then(data => {
            data.unshift({
              name_with_namespace: __('Any'),
            });
            data.splice(1, 0, { type: 'divider' });

            return data;
          })
          .then(data => callback(data))
          .catch(() => new Flash(__('Error fetching projects')));
      },
      id(obj) {
        return obj.id;
      },
      text(obj) {
        return obj.name_with_namespace;
      },
      clicked: () => Search.submitSearch(),
    });

    Project.initRefSwitcher();
  }

  eventListeners() {
    $(document)
      .off('keyup', this.searchInput)
      .on('keyup', this.searchInput, this.searchKeyUp);
    $(document)
      .off('click', this.searchClear)
      .on('click', this.searchClear, this.clearSearchField.bind(this));

    $('a.js-search-clear')
      .off('click', this.clearSearchFilter)
      .on('click', this.clearSearchFilter);
  }

  static submitSearch() {
    return $('.js-search-form').submit();
  }

  searchKeyUp() {
    const $input = $(this);
    if ($input.val() === '') {
      $('.js-search-clear').addClass('hidden');
    } else {
      $('.js-search-clear').removeClass('hidden');
    }
  }

  clearSearchField() {
    return $(this.searchInput)
      .val('')
      .trigger('keyup')
      .focus();
  }

  // We need to manually follow the link on the anchors
  // that have this event bound, as their `click` default
  // behavior is prevented by the toggle logic.
  /* eslint-disable-next-line class-methods-use-this */
  clearSearchFilter(ev) {
    const $target = $(ev.currentTarget);

    visitUrl($target.href);
    ev.stopPropagation();
  }

  getProjectsData(term) {
    return new Promise(resolve => {
      if (this.groupId) {
        Api.groupProjects(this.groupId, term, {}, resolve);
      } else {
        Api.projects(
          term,
          {
            order_by: 'id',
          },
          resolve,
        );
      }
    });
  }
}
