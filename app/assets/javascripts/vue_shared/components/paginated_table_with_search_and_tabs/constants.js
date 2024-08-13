export const tdClass = 'table-col gl-flex d-md-table-cell gl-items-center gl-whitespace-nowrap';
export const bodyTrClass =
  'gl-border-1 gl-border-t-solid gl-border-gray-100 hover:gl-cursor-pointer hover:gl-bg-gray-50 hover:gl-border-b-solid';

export const defaultPageSize = 20;

export const initialPaginationState = {
  page: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: defaultPageSize,
  lastPageSize: null,
};
