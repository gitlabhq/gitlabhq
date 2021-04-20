import { LIST_KEY_PROJECT, SORT_FIELDS } from './constants';

export const sortableFields = (isGroupPage) =>
  SORT_FIELDS.filter((f) => f.orderBy !== LIST_KEY_PROJECT || isGroupPage);

/**
 * A small util function that works out if the delete action has deleted the
 * last item on the current paginated page and if so, returns the previous
 * page. This ensures the user won't end up on an empty paginated page.
 *
 * @param {number} currentPage The current page the user is on
 * @param {number} perPage Number of items to display per page
 * @param {number} totalPackages The total number of items
 */
export const getNewPaginationPage = (currentPage, perPage, totalItems) => {
  if (totalItems <= perPage) {
    return 1;
  }

  if (currentPage > 1 && (currentPage - 1) * perPage >= totalItems) {
    return currentPage - 1;
  }

  return currentPage;
};
