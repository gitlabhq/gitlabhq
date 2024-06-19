import * as commonUtils from '~/lib/utils/common_utils';
import * as types from '~/packages_and_registries/infrastructure_registry/list/stores/mutation_types';
import mutations from '~/packages_and_registries/infrastructure_registry/list/stores/mutations';
import createState from '~/packages_and_registries/infrastructure_registry/list/stores/state';
import { npmPackage, mavenPackage } from '../../mock_data';

describe('Mutations Registry Store', () => {
  let mockState;
  beforeEach(() => {
    mockState = createState();
  });

  describe('SET_PACKAGE_LIST_SUCCESS', () => {
    it('should set a packages list', () => {
      const payload = [npmPackage, mavenPackage];
      const expectedState = { ...mockState, packages: payload };
      mutations[types.SET_PACKAGE_LIST_SUCCESS](mockState, payload);

      expect(mockState.packages).toEqual(expectedState.packages);
    });
  });

  describe('SET_MAIN_LOADING', () => {
    it('should set main loading', () => {
      mutations[types.SET_MAIN_LOADING](mockState, true);

      expect(mockState.isLoading).toEqual(true);
    });
  });

  describe('SET_PAGINATION', () => {
    const mockPagination = { perPage: 10, page: 1 };
    beforeEach(() => {
      commonUtils.normalizeHeaders = jest.fn().mockReturnValue('baz');
      commonUtils.parseIntPagination = jest.fn().mockReturnValue(mockPagination);
    });
    it('should set a parsed pagination', () => {
      mutations[types.SET_PAGINATION](mockState, 'foo');
      expect(commonUtils.normalizeHeaders).toHaveBeenCalledWith('foo');
      expect(commonUtils.parseIntPagination).toHaveBeenCalledWith('baz');
      expect(mockState.pagination).toEqual(mockPagination);
    });
  });

  describe('SET_SORTING', () => {
    it('should merge the sorting object with sort value', () => {
      mutations[types.SET_SORTING](mockState, { sort: 'desc' });
      expect(mockState.sorting).toEqual({ ...mockState.sorting, sort: 'desc' });
    });

    it('should merge the sorting object with order_by value', () => {
      mutations[types.SET_SORTING](mockState, { orderBy: 'foo' });
      expect(mockState.sorting).toEqual({ ...mockState.sorting, orderBy: 'foo' });
    });
  });

  describe('SET_FILTER', () => {
    it('should set the filter query', () => {
      mutations[types.SET_FILTER](mockState, 'foo');
      expect(mockState.filter).toEqual('foo');
    });
  });
});
