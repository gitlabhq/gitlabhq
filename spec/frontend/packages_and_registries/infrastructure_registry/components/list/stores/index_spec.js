import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import Api from '~/api';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  FETCH_PACKAGES_LIST_ERROR_MESSAGE,
  MISSING_DELETE_PATH_ERROR,
} from '~/packages_and_registries/infrastructure_registry/list/constants';
import { useInfrastructureList } from '~/packages_and_registries/infrastructure_registry/list/stores';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages_and_registries/shared/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { packageList } from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/api.js');

describe('~/packages_and_registries/infrastructure_registry/list/stores', () => {
  let store;
  let axiosMock;
  const headers = {
    'X-PAGE': '1',
    'X-PER-PAGE': '20',
    'X-TOTAL': '50',
    'X-TOTAL-PAGES': '3',
    'X-NEXT-PAGE': '2',
    'X-PREV-PAGE': '',
  };
  const expectedPagination = {
    perPage: 20,
    page: 1,
    total: 50,
    totalPages: 3,
    nextPage: 2,
    previousPage: NaN,
  };

  beforeAll(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  afterAll(() => {
    axiosMock.restore();
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useInfrastructureList();
    Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo', headers });
    Api.groupPackages = jest.fn().mockResolvedValue({ data: 'baz', headers });
  });

  describe('setLoading', () => {
    it('sets isLoading', () => {
      store.setLoading(true);

      expect(store.isLoading).toBe(true);
    });
  });

  describe('setSorting', () => {
    it('merges sort into sorting state', () => {
      store.setSorting({ sort: 'asc' });

      expect(store.sorting).toEqual({ sort: 'asc', orderBy: 'created_at' });
    });

    it('merges orderBy into sorting state', () => {
      store.setSorting({ orderBy: 'version' });

      expect(store.sorting).toEqual({ sort: 'desc', orderBy: 'version' });
    });
  });

  describe('setFilter', () => {
    it('sets the filter', () => {
      store.setFilter('foo');

      expect(store.filter).toBe('foo');
    });
  });

  describe('requestPackagesList', () => {
    it('sets isLoading=true while the request is in flight', () => {
      Api.projectPackages = jest.fn().mockReturnValueOnce(new Promise(() => {}));

      store.requestPackagesList({ isGroupPage: false, resourceId: 1 });

      expect(store.isLoading).toBe(true);
    });

    it('fetches group packages when isGroupPage is true', async () => {
      store.$patch({ sorting: { sort: 'asc', orderBy: 'version' }, filter: [] });

      await store.requestPackagesList({ isGroupPage: true, resourceId: 2 });

      expect(Api.groupPackages).toHaveBeenCalledWith(2, {
        params: {
          page: 1,
          per_page: 20,
          sort: 'asc',
          order_by: 'version',
          package_type: 'terraform_module',
        },
      });
      expect(store.packages).toBe('baz');
      expect(store.isLoading).toBe(false);
    });

    it('fetches project packages with type terraform_module', async () => {
      store.$patch({ sorting: { sort: 'asc', orderBy: 'version' }, filter: [] });

      await store.requestPackagesList({ isGroupPage: false, resourceId: 1 });

      expect(Api.projectPackages).toHaveBeenCalledWith(1, {
        params: {
          page: 1,
          per_page: 20,
          sort: 'asc',
          order_by: 'version',
          package_type: 'terraform_module',
        },
      });
      expect(store.packages).toBe('foo');
      expect(store.pagination).toEqual(expectedPagination);
    });

    it('creates an alert and resets isLoading on API error', async () => {
      Api.projectPackages = jest.fn().mockRejectedValue();

      await store.requestPackagesList({ isGroupPage: false, resourceId: 2 });

      expect(createAlert).toHaveBeenCalledWith({ message: FETCH_PACKAGES_LIST_ERROR_MESSAGE });
      expect(store.isLoading).toBe(false);
    });

    it('passes package_name from a FILTERED_SEARCH_TERM filter token', async () => {
      store.$patch({
        sorting: { sort: 'asc', orderBy: 'version' },
        filter: [{ type: FILTERED_SEARCH_TERM, value: { data: 'my-pkg' } }],
      });

      await store.requestPackagesList({ isGroupPage: false, resourceId: 1 });

      expect(Api.projectPackages).toHaveBeenCalledWith(1, {
        params: {
          page: 1,
          per_page: 20,
          sort: 'asc',
          order_by: 'version',
          package_type: 'terraform_module',
          package_name: 'my-pkg',
        },
      });
    });

    it('omits package_name when the filter is empty', async () => {
      store.$patch({
        sorting: { sort: 'asc', orderBy: 'version' },
        filter: [],
      });

      await store.requestPackagesList({ isGroupPage: false, resourceId: 1 });

      const [, config] = Api.projectPackages.mock.calls[0];
      expect(config.params.package_name).toBeUndefined();
    });
  });

  describe('requestDeletePackage', () => {
    const payload = {
      _links: { delete_api_path: '/delete/path' },
      isGroupPage: false,
      resourceId: 1,
    };

    it('sets isLoading=true while the delete request is in flight', () => {
      axiosMock.onDelete(payload._links.delete_api_path).replyOnce(() => new Promise(() => {}));

      store.requestDeletePackage(payload);

      expect(store.isLoading).toBe(true);
    });

    it('deletes the package and refreshes the list on success', async () => {
      axiosMock.onDelete(payload._links.delete_api_path).replyOnce(HTTP_STATUS_OK);
      store.$patch({ pagination: { page: 1, perPage: 20, total: 1 } });

      await store.requestDeletePackage(payload);

      expect(Api.projectPackages).toHaveBeenCalledWith(payload.resourceId, {
        params: {
          page: 1,
          per_page: 20,
          sort: 'desc',
          order_by: 'created_at',
          package_type: 'terraform_module',
        },
      });
      expect(createAlert).toHaveBeenCalledWith({
        message: DELETE_PACKAGE_SUCCESS_MESSAGE,
        variant: VARIANT_SUCCESS,
      });
    });

    describe('on API error', () => {
      beforeEach(() => {
        axiosMock.onDelete(payload._links.delete_api_path).replyOnce(HTTP_STATUS_BAD_REQUEST);
      });

      it('creates an alert with the default error message and resets isLoading', async () => {
        await store.requestDeletePackage(payload);

        expect(createAlert).toHaveBeenCalledWith({ message: DELETE_PACKAGE_ERROR_MESSAGE });
        expect(createAlert).not.toHaveBeenCalledWith({
          message: DELETE_PACKAGE_SUCCESS_MESSAGE,
          variant: VARIANT_SUCCESS,
        });
        expect(store.isLoading).toBe(false);
      });
    });

    describe('when the server returns an error message', () => {
      const serverMessage = 'Package is deletion protected.';

      beforeEach(() => {
        axiosMock
          .onDelete(payload._links.delete_api_path)
          .replyOnce(HTTP_STATUS_BAD_REQUEST, { message: serverMessage });
      });

      it('displays the server error message and resets isLoading', async () => {
        await store.requestDeletePackage(payload);

        expect(createAlert).toHaveBeenCalledWith({ message: serverMessage });
        expect(createAlert).not.toHaveBeenCalledWith({
          message: DELETE_PACKAGE_SUCCESS_MESSAGE,
          variant: VARIANT_SUCCESS,
        });
        expect(store.isLoading).toBe(false);
      });
    });

    it.each`
      property             | actionPayload
      ${'_links'}          | ${{}}
      ${'delete_api_path'} | ${{ _links: {} }}
    `(
      'rejects with MISSING_DELETE_PATH_ERROR and creates an alert when $property is missing',
      async ({ actionPayload }) => {
        await expect(store.requestDeletePackage(actionPayload)).rejects.toThrow(
          MISSING_DELETE_PATH_ERROR,
        );
        expect(createAlert).toHaveBeenCalledWith({ message: DELETE_PACKAGE_ERROR_MESSAGE });
        expect(store.isLoading).toBe(false);
        expect(axiosMock.history.delete).toHaveLength(0);
      },
    );
  });

  describe('getList', () => {
    it('returns a list of packages', () => {
      store.$patch({ packages: packageList });

      const result = store.getList;

      expect(result).toHaveLength(packageList.length);
      expect(result[0].name).toBe('Test package');
    });

    it('adds projectPathName', () => {
      store.$patch({ packages: packageList });

      const result = store.getList;

      expect(result[0].projectPathName).toMatchInlineSnapshot(`"foo / bar / baz"`);
    });
  });
});
