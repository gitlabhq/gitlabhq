import $ from 'jquery';
import Api from './api';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default () => {
  initDeprecatedJQueryDropdown($('#js-project-dropdown'), {
    data: (term, callback) => {
      Api.projects(
        term,
        {
          order_by: 'last_activity_at',
        },
        data => {
          callback(data);
        },
      );
    },
    text: project => project.name_with_namespace || project.name,
    selectable: true,
    fieldName: 'author_id',
    filterable: true,
    search: {
      fields: ['name_with_namespace'],
    },
    id: data => data.id,
    isSelected: data => data.id === 2,
  });
};
