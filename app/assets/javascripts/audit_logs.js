/* eslint-disable class-methods-use-this, no-unneeded-ternary, quote-props, no-new */
/* global GroupsSelect */
/* global ProjectSelect */

import UsersSelect from './users_select';
import './groups_select';
import './project_select';

class AuditLogs {
  constructor() {
    this.initFilters();
  }

  initFilters() {
    new ProjectSelect();
    new GroupsSelect();
    new UsersSelect();

    this.initFilterDropdown($('.js-type-filter'), 'event_type', null, () => {
      $('.hidden-filter-value').val('');
      $('form.filter-form').submit();
    });

    $('.project-item-select').on('click', () => {
      $('form.filter-form').submit();
    });
  }

  initFilterDropdown($dropdown, fieldName, searchFields, cb) {
    const dropdownOptions = {
      fieldName,
      selectable: true,
      filterable: searchFields ? true : false,
      search: { fields: searchFields },
      data: $dropdown.data('data'),
      clicked: () => $dropdown.closest('form.filter-form').submit(),
    };
    if (cb) {
      dropdownOptions.clicked = cb;
    }
    $dropdown.glDropdown(dropdownOptions);
  }
}

export default AuditLogs;
