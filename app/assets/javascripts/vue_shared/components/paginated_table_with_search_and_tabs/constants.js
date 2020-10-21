import { __ } from '~/locale';

export const tdClass =
  'table-col gl-display-flex d-md-table-cell gl-align-items-center gl-white-space-nowrap';
export const thClass = 'gl-hover-bg-blue-50';
export const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 gl-hover-cursor-pointer gl-hover-bg-blue-50 gl-hover-border-b-solid gl-hover-border-blue-200';

export const defaultPageSize = 20;

export const initialPaginationState = {
  page: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: defaultPageSize,
  lastPageSize: null,
};

export const defaultI18n = {
  searchPlaceholder: __('Search or filter results…'),
};
