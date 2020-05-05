import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import * as actions from '~/registry/explorer/stores/actions';
import * as types from '~/registry/explorer/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import { TEST_HOST } from 'helpers/test_constants';
import { reposServerResponse, registryServerResponse } from '../mock_data';

jest.mock('~/flash.js');

describe('Actions RegistryExplorer Store', () => {
  let mock;
  const endpoint = `${TEST_HOST}/endpoint.json`;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('sets initial state', done => {
    const initialState = {
      config: {
        endpoint,
      },
    };

    testAction(
      actions.setInitialState,
      initialState,
      null,
      [{ type: types.SET_INITIAL_STATE, payload: initialState }],
      [],
      done,
    );
  });

  it('setShowGarbageCollectionTip', done => {
    testAction(
      actions.setShowGarbageCollectionTip,
      true,
      null,
      [{ type: types.SET_SHOW_GARBAGE_COLLECTION_TIP, payload: true }],
      [],
      done,
    );
  });

  describe('receives api responses', () => {
    const response = {
      data: [1, 2, 3],
      headers: {
        page: 1,
        perPage: 10,
      },
    };

    it('images list response', done => {
      testAction(
        actions.receiveImagesListSuccess,
        response,
        null,
        [
          { type: types.SET_IMAGES_LIST_SUCCESS, payload: response.data },
          { type: types.SET_PAGINATION, payload: response.headers },
        ],
        [],
        done,
      );
    });

    it('tags list response', done => {
      testAction(
        actions.receiveTagsListSuccess,
        response,
        null,
        [
          { type: types.SET_TAGS_LIST_SUCCESS, payload: response.data },
          { type: types.SET_TAGS_PAGINATION, payload: response.headers },
        ],
        [],
        done,
      );
    });
  });

  describe('fetch images list', () => {
    it('sets the imagesList and pagination', done => {
      mock.onGet(endpoint).replyOnce(200, reposServerResponse, {});

      testAction(
        actions.requestImagesList,
        {},
        {
          config: {
            endpoint,
          },
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [{ type: 'receiveImagesListSuccess', payload: { data: reposServerResponse, headers: {} } }],
        done,
      );
    });

    it('should create flash on error', done => {
      testAction(
        actions.requestImagesList,
        {},
        {
          config: {
            endpoint: null,
          },
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('fetch tags list', () => {
    const url = `${endpoint}/1}`;
    const params = window.btoa(JSON.stringify({ tags_path: `${endpoint}/1}` }));

    it('sets the tagsList', done => {
      mock.onGet(url).replyOnce(200, registryServerResponse, {});

      testAction(
        actions.requestTagsList,
        { params },
        {},
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [
          {
            type: 'receiveTagsListSuccess',
            payload: { data: registryServerResponse, headers: {} },
          },
        ],
        done,
      );
    });

    it('should create flash on error', done => {
      testAction(
        actions.requestTagsList,
        { params },
        {},
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('request delete single tag', () => {
    it('successfully performs the delete request', done => {
      const deletePath = 'delete/path';
      const params = window.btoa(JSON.stringify({ tags_path: `${endpoint}/1}`, id: 1 }));

      mock.onDelete(deletePath).replyOnce(200);

      testAction(
        actions.requestDeleteTag,
        {
          tag: {
            destroy_path: deletePath,
          },
          params,
        },
        {
          tagsPagination: {},
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [
          {
            type: 'setShowGarbageCollectionTip',
            payload: true,
          },
          {
            type: 'requestTagsList',
            payload: { pagination: {}, params },
          },
        ],
        done,
      );
    });

    it('should turn off loading on error', done => {
      testAction(
        actions.requestDeleteTag,
        {
          tag: {
            destroy_path: null,
          },
        },
        {},
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [],
      ).catch(() => done());
    });
  });

  describe('request delete multiple tags', () => {
    const url = `project-path/registry/repository/foo/tags`;
    const params = window.btoa(JSON.stringify({ tags_path: `${url}?format=json` }));

    it('successfully performs the delete request', done => {
      mock.onDelete(`${url}/bulk_destroy`).replyOnce(200);

      testAction(
        actions.requestDeleteTags,
        {
          ids: [1, 2],
          params,
        },
        {
          tagsPagination: {},
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [
          {
            type: 'setShowGarbageCollectionTip',
            payload: true,
          },
          {
            type: 'requestTagsList',
            payload: { pagination: {}, params },
          },
        ],
        done,
      );
    });

    it('should turn off loading on error', done => {
      mock.onDelete(url).replyOnce(500);

      testAction(
        actions.requestDeleteTags,
        {
          ids: [1, 2],
          params,
        },
        {
          tagsPagination: {},
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [],
      ).catch(() => done());
    });
  });

  describe('request delete single image', () => {
    const image = {
      destroy_path: 'delete/path',
    };

    it('successfully performs the delete request', done => {
      mock.onDelete(image.destroy_path).replyOnce(200);

      testAction(
        actions.requestDeleteImage,
        image,
        {},
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.UPDATE_IMAGE, payload: { ...image, deleting: true } },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [],
        done,
      );
    });

    it('should turn off loading on error', done => {
      mock.onDelete(image.destroy_path).replyOnce(400);
      testAction(
        actions.requestDeleteImage,
        image,
        {},
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [],
      ).catch(() => done());
    });
  });
});
