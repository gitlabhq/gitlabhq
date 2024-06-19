import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { createAlert } from '~/alert';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { MISSING_DELETE_PATH_ERROR } from '~/packages_and_registries/infrastructure_registry/list/constants';
import * as actions from '~/packages_and_registries/infrastructure_registry/list/stores/actions';
import * as types from '~/packages_and_registries/infrastructure_registry/list/stores/mutation_types';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages_and_registries/shared/constants';

jest.mock('~/alert');
jest.mock('~/api.js');

describe('Actions Package list store', () => {
  const headers = 'bar';
  let mock;

  beforeEach(() => {
    Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo', headers });
    Api.groupPackages = jest.fn().mockResolvedValue({ data: 'baz', headers });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestPackagesList', () => {
    const sorting = {
      sort: 'asc',
      orderBy: 'version',
    };

    const filter = [];

    it('should fetch the group packages list when isGroupPage is true', async () => {
      await testAction(
        actions.requestPackagesList,
        { isGroupPage: true, resourceId: 2 },
        { sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'baz', headers } },
          { type: 'setLoading', payload: false },
        ],
      );
      expect(Api.groupPackages).toHaveBeenCalledWith(2, {
        params: {
          page: 1,
          per_page: 20,
          sort: sorting.sort,
          order_by: sorting.orderBy,
          package_type: 'terraform_module',
        },
      });
    });

    it('should fetch packages with type terraform_module', async () => {
      await testAction(
        actions.requestPackagesList,
        { isGroupPage: false, resourceId: 1 },
        { sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'foo', headers } },
          { type: 'setLoading', payload: false },
        ],
      );
      expect(Api.projectPackages).toHaveBeenCalledWith(1, {
        params: {
          page: 1,
          per_page: 20,
          sort: sorting.sort,
          order_by: sorting.orderBy,
          package_type: 'terraform_module',
        },
      });
    });

    it('should create alert on API error', async () => {
      Api.projectPackages = jest.fn().mockRejectedValue();
      await testAction(
        actions.requestPackagesList,
        { isGroupPage: false, resourceId: 2 },
        { sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'setLoading', payload: false },
        ],
      );
      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('receivePackagesListSuccess', () => {
    it('should set received packages', () => {
      const data = 'foo';

      return testAction(
        actions.receivePackagesListSuccess,
        { data, headers },
        null,
        [
          { type: types.SET_PACKAGE_LIST_SUCCESS, payload: data },
          { type: types.SET_PAGINATION, payload: headers },
        ],
        [],
      );
    });
  });

  describe('setLoading', () => {
    it('should commit set main loading', () => {
      return testAction(
        actions.setLoading,
        true,
        null,
        [{ type: types.SET_MAIN_LOADING, payload: true }],
        [],
      );
    });
  });

  describe('requestDeletePackage', () => {
    const payload = {
      _links: {
        delete_api_path: 'foo',
      },
      isGroupPage: false,
      resourceId: 1,
    };
    it('should perform a delete operation on _links.delete_api_path', () => {
      mock.onDelete(payload._links.delete_api_path).replyOnce(HTTP_STATUS_OK);
      Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo' });

      return testAction(
        actions.requestDeletePackage,
        payload,
        { pagination: { page: 1 } },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'requestPackagesList', payload: { page: 1, isGroupPage: false, resourceId: 1 } },
        ],
      );
    });

    it('should stop the loading and call create alert on api error', async () => {
      mock.onDelete(payload._links.delete_api_path).replyOnce(HTTP_STATUS_BAD_REQUEST);
      await testAction(
        actions.requestDeletePackage,
        payload,
        null,
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'setLoading', payload: false },
        ],
      );
      expect(createAlert).toHaveBeenCalled();
    });

    it.each`
      property             | actionPayload
      ${'_links'}          | ${{}}
      ${'delete_api_path'} | ${{ _links: {} }}
    `('should reject and createAlert when $property is missing', ({ actionPayload }) => {
      return testAction(actions.requestDeletePackage, actionPayload, null, [], []).catch((e) => {
        expect(e).toEqual(new Error(MISSING_DELETE_PATH_ERROR));
        expect(createAlert).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_ERROR_MESSAGE,
        });
      });
    });
  });

  describe('setSorting', () => {
    it('should commit SET_SORTING', () => {
      return testAction(
        actions.setSorting,
        'foo',
        null,
        [{ type: types.SET_SORTING, payload: 'foo' }],
        [],
      );
    });
  });

  describe('setFilter', () => {
    it('should commit SET_FILTER', () => {
      return testAction(
        actions.setFilter,
        'foo',
        null,
        [{ type: types.SET_FILTER, payload: 'foo' }],
        [],
      );
    });
  });
});
