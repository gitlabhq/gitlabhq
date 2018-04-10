import $ from 'jquery';
import Flash from '~/flash';
import Api from '~/api';

export default class Search {
  constructor() {
    const $groupDropdown = $('.js-search-group-dropdown');
    const $projectDropdown = $('.js-search-project-dropdown');

    this.searchInput = '.js-search-input';
    this.searchClear = '.js-search-clear';

    this.groupId = $groupDropdown.data('groupId');
    this.eventListeners();

    $groupDropdown.glDropdown({
      selectable: true,
      filterable: true,
      filterRemote: true,
      fieldName: 'group_id',
      search: {
        fields: ['full_name'],
      },
      data(term, callback) {
        return Api.groups(term, {}, (data) => {
          data.unshift({
            full_name: 'Any',
          });
          data.splice(1, 0, 'divider');
          return callback(data);
        });
      },
      id(obj) {
        return obj.id;
      },
      text(obj) {
        return obj.full_name;
      },
      toggleLabel(obj) {
        return `${($groupDropdown.data('defaultLabel'))} ${obj.full_name}`;
      },
      clicked: () => Search.submitSearch(),
    });

    $projectDropdown.glDropdown({
      selectable: true,
      filterable: true,
      filterRemote: true,
      fieldName: 'project_id',
      search: {
        fields: ['name'],
      },
      data: (term, callback) => {
        this.getProjectsData(term)
          .then((data) => {
            data.unshift({
              name_with_namespace: 'Any',
            });
            data.splice(1, 0, 'divider');

            return data;
          })
          .then(data => callback(data))
          .catch(() => new Flash('Error fetching projects'));
      },
      id(obj) {
        return obj.id;
      },
      text(obj) {
        return obj.name_with_namespace;
      },
      toggleLabel(obj) {
        return `${($projectDropdown.data('defaultLabel'))} ${obj.name_with_namespace}`;
      },
      clicked: () => Search.submitSearch(),
    });
  }

  eventListeners() {
    $(document)
      .off('keyup', this.searchInput)
      .on('keyup', this.searchInput, this.searchKeyUp);
    $(document)
      .off('click', this.searchClear)
      .on('click', this.searchClear, this.clearSearchField.bind(this));
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
    return $(this.searchInput).val('').trigger('keyup').focus();
  }

  getProjectsData(term) {
    return new Promise((resolve) => {
      if (this.groupId) {
        Api.groupProjects(this.groupId, term, resolve);
      } else {
        Api.projects(term, {
          order_by: 'id',
        }, resolve);
      }
    });
  }
}
