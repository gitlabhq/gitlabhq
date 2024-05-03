export const tdClass =
  'table-col gl-display-flex d-md-table-cell gl-align-items-center gl-whitespace-nowrap';
export const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 gl-hover-cursor-pointer gl-hover-bg-gray-50 gl-hover-border-b-solid';

export const defaultPageSize = 20;

export const initialPaginationState = {
  page: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: defaultPageSize,
  lastPageSize: null,
};
