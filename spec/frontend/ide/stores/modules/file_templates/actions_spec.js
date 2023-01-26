import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/ide/stores/modules/file_templates/actions';
import * as types from '~/ide/stores/modules/file_templates/mutation_types';
import createState from '~/ide/stores/modules/file_templates/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('IDE file templates actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = createState();

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestTemplateTypes', () => {
    it('commits REQUEST_TEMPLATE_TYPES', () => {
      return testAction(
        actions.requestTemplateTypes,
        null,
        state,
        [{ type: types.REQUEST_TEMPLATE_TYPES }],
        [],
      );
    });
  });

  describe('receiveTemplateTypesError', () => {
    it('commits RECEIVE_TEMPLATE_TYPES_ERROR and dispatches setErrorMessage', () => {
      return testAction(
        actions.receiveTemplateTypesError,
        null,
        state,
        [{ type: types.RECEIVE_TEMPLATE_TYPES_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              action: expect.any(Function),
              actionText: 'Please try again',
              text: 'Error loading template types.',
            },
          },
        ],
      );
    });
  });

  describe('receiveTemplateTypesSuccess', () => {
    it('commits RECEIVE_TEMPLATE_TYPES_SUCCESS', () => {
      return testAction(
        actions.receiveTemplateTypesSuccess,
        'test',
        state,
        [{ type: types.RECEIVE_TEMPLATE_TYPES_SUCCESS, payload: 'test' }],
        [],
      );
    });
  });

  describe('fetchTemplateTypes', () => {
    describe('success', () => {
      const pages = [[{ name: 'MIT' }], [{ name: 'Apache' }], [{ name: 'CC' }]];

      beforeEach(() => {
        mock.onGet(/api\/(.*)\/templates\/licenses/).reply(({ params }) => {
          const pageNum = params.page;
          const page = pages[pageNum - 1];
          const hasNextPage = pageNum < pages.length;

          return [HTTP_STATUS_OK, page, hasNextPage ? { 'X-NEXT-PAGE': pageNum + 1 } : {}];
        });
      });

      it('rejects if selectedTemplateType is empty', async () => {
        const dispatch = jest.fn().mockName('dispatch');

        await expect(actions.fetchTemplateTypes({ dispatch, state })).rejects.toBeUndefined();
        expect(dispatch).not.toHaveBeenCalled();
      });

      it('dispatches actions', () => {
        state.selectedTemplateType = { key: 'licenses' };

        return testAction(
          actions.fetchTemplateTypes,
          null,
          state,
          [],
          [
            { type: 'requestTemplateTypes' },
            { type: 'receiveTemplateTypesSuccess', payload: pages[0] },
            { type: 'receiveTemplateTypesSuccess', payload: pages[0].concat(pages[1]) },
            {
              type: 'receiveTemplateTypesSuccess',
              payload: pages[0].concat(pages[1]).concat(pages[2]),
            },
          ],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/templates\/licenses/).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches actions', () => {
        state.selectedTemplateType = { key: 'licenses' };

        return testAction(
          actions.fetchTemplateTypes,
          null,
          state,
          [],
          [{ type: 'requestTemplateTypes' }, { type: 'receiveTemplateTypesError' }],
        );
      });
    });
  });

  describe('setSelectedTemplateType', () => {
    it('commits SET_SELECTED_TEMPLATE_TYPE', () => {
      const commit = jest.fn().mockName('commit');
      const options = {
        commit,
        dispatch() {},
        rootGetters: { activeFile: { name: 'test', prevPath: '' } },
      };

      actions.setSelectedTemplateType(options, { name: 'test' });

      expect(commit).toHaveBeenCalledWith(types.SET_SELECTED_TEMPLATE_TYPE, { name: 'test' });
    });

    it('dispatches discardFileChanges if prevPath matches templates name', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const options = {
        commit() {},

        dispatch,
        rootGetters: { activeFile: { name: 'test', path: 'test', prevPath: 'test' } },
      };

      actions.setSelectedTemplateType(options, { name: 'test' });

      expect(dispatch).toHaveBeenCalledWith('discardFileChanges', 'test', { root: true });
    });

    it('dispatches renameEntry if file name doesnt match', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const options = {
        commit() {},

        dispatch,
        rootGetters: { activeFile: { name: 'oldtest', path: 'oldtest', prevPath: '' } },
      };

      actions.setSelectedTemplateType(options, { name: 'test' });

      expect(dispatch).toHaveBeenCalledWith(
        'renameEntry',
        { path: 'oldtest', name: 'test' },
        { root: true },
      );
    });
  });

  describe('receiveTemplateError', () => {
    it('dispatches setErrorMessage', () => {
      return testAction(
        actions.receiveTemplateError,
        'test',
        state,
        [],
        [
          {
            type: 'setErrorMessage',
            payload: {
              action: expect.any(Function),
              actionText: 'Please try again',
              text: 'Error loading template.',
              actionPayload: 'test',
            },
          },
        ],
      );
    });
  });

  describe('fetchTemplate', () => {
    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet(/api\/(.*)\/templates\/licenses\/mit/)
          .replyOnce(HTTP_STATUS_OK, { content: 'MIT content' });
        mock
          .onGet(/api\/(.*)\/templates\/licenses\/testing/)
          .replyOnce(HTTP_STATUS_OK, { content: 'testing content' });
      });

      it('dispatches setFileTemplate if template already has content', () => {
        const template = { content: 'already has content' };

        return testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'setFileTemplate', payload: template }],
        );
      });

      it('dispatches success', () => {
        const template = { key: 'mit' };

        state.selectedTemplateType = { key: 'licenses' };

        return testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'setFileTemplate', payload: { content: 'MIT content' } }],
        );
      });

      it('dispatches success and uses name key for API call', () => {
        const template = { name: 'testing' };

        state.selectedTemplateType = { key: 'licenses' };

        return testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'setFileTemplate', payload: { content: 'testing content' } }],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock
          .onGet(/api\/(.*)\/templates\/licenses\/mit/)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches error', () => {
        const template = { name: 'testing' };

        state.selectedTemplateType = { key: 'licenses' };

        return testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'receiveTemplateError', payload: template }],
        );
      });
    });
  });

  describe('setFileTemplate', () => {
    it('dispatches changeFileContent', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const commit = jest.fn().mockName('commit');
      const rootGetters = { activeFile: { path: 'test' } };

      actions.setFileTemplate({ dispatch, commit, rootGetters }, { content: 'content' });

      expect(dispatch).toHaveBeenCalledWith(
        'changeFileContent',
        { path: 'test', content: 'content' },
        { root: true },
      );
    });

    it('commits SET_UPDATE_SUCCESS', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const commit = jest.fn().mockName('commit');
      const rootGetters = { activeFile: { path: 'test' } };

      actions.setFileTemplate({ dispatch, commit, rootGetters }, { content: 'content' });

      expect(commit).toHaveBeenCalledWith('SET_UPDATE_SUCCESS', true);
    });
  });

  describe('undoFileTemplate', () => {
    it('dispatches changeFileContent', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const commit = jest.fn().mockName('commit');
      const rootGetters = { activeFile: { path: 'test', raw: 'raw content' } };

      actions.undoFileTemplate({ dispatch, commit, rootGetters });

      expect(dispatch).toHaveBeenCalledWith(
        'changeFileContent',
        { path: 'test', content: 'raw content' },
        { root: true },
      );
    });

    it('commits SET_UPDATE_SUCCESS', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const commit = jest.fn().mockName('commit');
      const rootGetters = { activeFile: { path: 'test', raw: 'raw content' } };

      actions.undoFileTemplate({ dispatch, commit, rootGetters });

      expect(commit).toHaveBeenCalledWith('SET_UPDATE_SUCCESS', false);
    });

    it('dispatches discardFileChanges if file has prevPath', () => {
      const dispatch = jest.fn().mockName('dispatch');
      const rootGetters = { activeFile: { path: 'test', prevPath: 'newtest', raw: 'raw content' } };

      actions.undoFileTemplate({ dispatch, commit() {}, rootGetters });

      expect(dispatch).toHaveBeenCalledWith('discardFileChanges', 'test', { root: true });
    });
  });
});
