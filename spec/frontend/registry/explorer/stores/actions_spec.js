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
    const path = window.btoa(JSON.stringify({ tags_path: `${endpoint}/1}` }));

    it('sets the tagsList', done => {
      mock.onGet(url).replyOnce(200, registryServerResponse, {});

      testAction(
        actions.requestTagsList,
        { id: path },
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
        { id: path },
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
      const url = window.btoa(`${endpoint}/1}`);

      mock.onDelete(deletePath).replyOnce(200);

      testAction(
        actions.requestDeleteTag,
        {
          tag: {
            destroy_path: deletePath,
          },
          imageId: url,
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
            type: 'requestTagsList',
            payload: { pagination: {}, id: url },
          },
        ],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });

    it('should show flash message on error', done => {
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
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('request delete multiple tags', () => {
    const imageId = 1;
    const projectPath = 'project-path';
    const url = `${projectPath}/registry/repository/${imageId}/tags/bulk_destroy`;

    it('successfully performs the delete request', done => {
      mock.onDelete(url).replyOnce(200);

      testAction(
        actions.requestDeleteTags,
        {
          ids: [1, 2],
          imageId,
        },
        {
          config: {
            projectPath,
          },
          tagsPagination: {},
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [
          {
            type: 'requestTagsList',
            payload: { pagination: {}, id: 1 },
          },
        ],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });

    it('should show flash message on error', done => {
      mock.onDelete(url).replyOnce(500);

      testAction(
        actions.requestDeleteTags,
        {
          ids: [1, 2],
          imageId,
        },
        {
          config: {
            projectPath,
          },
          tagsPagination: {},
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

  describe('request delete single image', () => {
    it('successfully performs the delete request', done => {
      const deletePath = 'delete/path';
      mock.onDelete(deletePath).replyOnce(200);

      testAction(
        actions.requestDeleteImage,
        deletePath,
        {
          pagination: {},
        },
        [
          { type: types.SET_MAIN_LOADING, payload: true },
          { type: types.SET_MAIN_LOADING, payload: false },
        ],
        [
          {
            type: 'requestImagesList',
            payload: { pagination: {} },
          },
        ],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });

    it('should show flash message on error', done => {
      testAction(
        actions.requestDeleteImage,
        null,
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
});
