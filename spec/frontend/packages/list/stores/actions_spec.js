import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import createFlash from '~/flash';
import { MISSING_DELETE_PATH_ERROR } from '~/packages/list/constants';
import * as actions from '~/packages/list/stores/actions';
import * as types from '~/packages/list/stores/mutation_types';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages/shared/constants';

jest.mock('~/flash.js');
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
    it('should fetch the project packages list when isGroupPage is false', (done) => {
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: false, resourceId: 1 }, sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'foo', headers } },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(Api.projectPackages).toHaveBeenCalledWith(1, {
            params: { page: 1, per_page: 20, sort: sorting.sort, order_by: sorting.orderBy },
          });
          done();
        },
      );
    });

    it('should fetch the group packages list when  isGroupPage is true', (done) => {
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: true, resourceId: 2 }, sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'baz', headers } },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(Api.groupPackages).toHaveBeenCalledWith(2, {
            params: { page: 1, per_page: 20, sort: sorting.sort, order_by: sorting.orderBy },
          });
          done();
        },
      );
    });

    it('should fetch packages of a certain type when a filter with a type is present', (done) => {
      const packageType = 'maven';

      testAction(
        actions.requestPackagesList,
        undefined,
        {
          config: { isGroupPage: false, resourceId: 1 },
          sorting,
          filter: [{ type: 'type', value: { data: 'maven' } }],
        },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'foo', headers } },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(Api.projectPackages).toHaveBeenCalledWith(1, {
            params: {
              page: 1,
              per_page: 20,
              sort: sorting.sort,
              order_by: sorting.orderBy,
              package_type: packageType,
            },
          });
          done();
        },
      );
    });

    it('should create flash on API error', (done) => {
      Api.projectPackages = jest.fn().mockRejectedValue();
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: false, resourceId: 2 }, sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });

    it('should force the terraform_module type when forceTerraform is true', (done) => {
      testAction(
        actions.requestPackagesList,
        undefined,
        { config: { isGroupPage: false, resourceId: 1, forceTerraform: true }, sorting, filter },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'receivePackagesListSuccess', payload: { data: 'foo', headers } },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(Api.projectPackages).toHaveBeenCalledWith(1, {
            params: {
              page: 1,
              per_page: 20,
              sort: sorting.sort,
              order_by: sorting.orderBy,
              package_type: 'terraform_module',
            },
          });
          done();
        },
      );
    });
  });

  describe('receivePackagesListSuccess', () => {
    it('should set received packages', (done) => {
      const data = 'foo';

      testAction(
        actions.receivePackagesListSuccess,
        { data, headers },
        null,
        [
          { type: types.SET_PACKAGE_LIST_SUCCESS, payload: data },
          { type: types.SET_PAGINATION, payload: headers },
        ],
        [],
        done,
      );
    });
  });

  describe('setInitialState', () => {
    it('should commit setInitialState', (done) => {
      testAction(
        actions.setInitialState,
        '1',
        null,
        [{ type: types.SET_INITIAL_STATE, payload: '1' }],
        [],
        done,
      );
    });
  });

  describe('setLoading', () => {
    it('should commit set main loading', (done) => {
      testAction(
        actions.setLoading,
        true,
        null,
        [{ type: types.SET_MAIN_LOADING, payload: true }],
        [],
        done,
      );
    });
  });

  describe('requestDeletePackage', () => {
    const payload = {
      _links: {
        delete_api_path: 'foo',
      },
    };
    it('should perform a delete operation on _links.delete_api_path', (done) => {
      mock.onDelete(payload._links.delete_api_path).replyOnce(200);
      Api.projectPackages = jest.fn().mockResolvedValue({ data: 'foo' });

      testAction(
        actions.requestDeletePackage,
        payload,
        { pagination: { page: 1 } },
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'requestPackagesList', payload: { page: 1 } },
        ],
        done,
      );
    });

    it('should stop the loading and call create flash on api error', (done) => {
      mock.onDelete(payload._links.delete_api_path).replyOnce(400);
      testAction(
        actions.requestDeletePackage,
        payload,
        null,
        [],
        [
          { type: 'setLoading', payload: true },
          { type: 'setLoading', payload: false },
        ],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });

    it.each`
      property             | actionPayload
      ${'_links'}          | ${{}}
      ${'delete_api_path'} | ${{ _links: {} }}
    `('should reject and createFlash when $property is missing', ({ actionPayload }, done) => {
      testAction(actions.requestDeletePackage, actionPayload, null, [], []).catch((e) => {
        expect(e).toEqual(new Error(MISSING_DELETE_PATH_ERROR));
        expect(createFlash).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_ERROR_MESSAGE,
        });
        done();
      });
    });
  });

  describe('setSorting', () => {
    it('should commit SET_SORTING', (done) => {
      testAction(
        actions.setSorting,
        'foo',
        null,
        [{ type: types.SET_SORTING, payload: 'foo' }],
        [],
        done,
      );
    });
  });

  describe('setFilter', () => {
    it('should commit SET_FILTER', (done) => {
      testAction(
        actions.setFilter,
        'foo',
        null,
        [{ type: types.SET_FILTER, payload: 'foo' }],
        [],
        done,
      );
    });
  });
});
