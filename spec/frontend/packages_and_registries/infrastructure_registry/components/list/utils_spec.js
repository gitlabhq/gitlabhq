import { SORT_FIELDS } from '~/packages_and_registries/infrastructure_registry/list/constants';
import {
  getNewPaginationPage,
  sortableFields,
} from '~/packages_and_registries/infrastructure_registry/list/utils';

describe('Packages list utils', () => {
  describe('sortableFields', () => {
    it('returns the correct list when is a project page', () => {
      expect(sortableFields()).toEqual(SORT_FIELDS.filter((f) => f.orderBy !== 'project_path'));
    });
    it('returns the full list on the group page', () => {
      expect(sortableFields(true)).toEqual(SORT_FIELDS);
    });
  });
  describe('packageTypeDisplay', () => {
    it('returns the current page when total items exceeds pagniation', () => {
      expect(getNewPaginationPage(2, 20, 21)).toBe(2);
    });

    it('returns the previous page when total items is lower than or equal to pagination', () => {
      expect(getNewPaginationPage(2, 20, 20)).toBe(1);
    });

    it('returns the first page when totalItems is lower than or equal to perPage', () => {
      expect(getNewPaginationPage(4, 20, 20)).toBe(1);
    });

    describe('works when a different perPage is used', () => {
      it('returns the current page', () => {
        expect(getNewPaginationPage(2, 10, 11)).toBe(2);
      });

      it('returns the previous page', () => {
        expect(getNewPaginationPage(2, 10, 10)).toBe(1);
      });
    });

    describe.each`
      currentPage | totalItems | expectedResult
      ${1}        | ${20}      | ${1}
      ${2}        | ${20}      | ${1}
      ${3}        | ${40}      | ${2}
      ${4}        | ${60}      | ${3}
    `(`works across numerious pages`, ({ currentPage, totalItems, expectedResult }) => {
      it(`when currentPage is ${currentPage} return to the previous page ${expectedResult}`, () => {
        expect(getNewPaginationPage(currentPage, 20, totalItems)).toBe(expectedResult);
      });
    });
  });
});
