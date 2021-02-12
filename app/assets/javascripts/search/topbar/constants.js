import { __ } from '~/locale';

export const ANY_OPTION = Object.freeze({
  id: null,
  name: __('Any'),
  name_with_namespace: __('Any'),
});

export const GROUP_DATA = {
  headerText: __('Filter results by group'),
  queryParam: 'group_id',
  selectedDisplayValue: 'name',
  itemsDisplayValue: 'full_name',
};

export const PROJECT_DATA = {
  headerText: __('Filter results by project'),
  queryParam: 'project_id',
  selectedDisplayValue: 'name_with_namespace',
  itemsDisplayValue: 'name_with_namespace',
};
