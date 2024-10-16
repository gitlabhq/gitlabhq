import { PAGE_SIZE, INITIAL_PAGE } from '~/badges/constants';

export const MOCK_PAGINATION = {
  perPage: PAGE_SIZE,
  page: INITIAL_PAGE,
  total: 20,
  totalPages: 2,
  nextPage: 2,
  previousPage: NaN,
};

export const MOCK_PAGINATION_HEADERS = {
  'X-PER-PAGE': MOCK_PAGINATION.perPage,
  'X-PAGE': MOCK_PAGINATION.page,
  'X-TOTAL': MOCK_PAGINATION.total,
  'X-TOTAL-PAGES': MOCK_PAGINATION.totalPages,
  'X-NEXT-PAGE': MOCK_PAGINATION.nextPage,
  'X-PREV-PAGE': MOCK_PAGINATION.previousPage,
};
