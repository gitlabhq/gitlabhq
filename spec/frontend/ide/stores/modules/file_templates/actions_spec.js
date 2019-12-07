import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import createState from '~/ide/stores/modules/file_templates/state';
import * as actions from '~/ide/stores/modules/file_templates/actions';
import * as types from '~/ide/stores/modules/file_templates/mutation_types';

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
    it('commits REQUEST_TEMPLATE_TYPES', done => {
      testAction(
        actions.requestTemplateTypes,
        null,
        state,
        [{ type: types.REQUEST_TEMPLATE_TYPES }],
        [],
        done,
      );
    });
  });

  describe('receiveTemplateTypesError', () => {
    it('commits RECEIVE_TEMPLATE_TYPES_ERROR and dispatches setErrorMessage', done => {
      testAction(
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
        done,
      );
    });
  });

  describe('receiveTemplateTypesSuccess', () => {
    it('commits RECEIVE_TEMPLATE_TYPES_SUCCESS', done => {
      testAction(
        actions.receiveTemplateTypesSuccess,
        'test',
        state,
        [{ type: types.RECEIVE_TEMPLATE_TYPES_SUCCESS, payload: 'test' }],
        [],
        done,
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

          return [200, page, hasNextPage ? { 'X-NEXT-PAGE': pageNum + 1 } : {}];
        });
      });

      it('rejects if selectedTemplateType is empty', done => {
        const dispatch = jest.fn().mockName('dispatch');

        actions
          .fetchTemplateTypes({ dispatch, state })
          .then(done.fail)
          .catch(() => {
            expect(dispatch).not.toHaveBeenCalled();

            done();
          });
      });

      it('dispatches actions', done => {
        state.selectedTemplateType = { key: 'licenses' };

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/templates\/licenses/).replyOnce(500);
      });

      it('dispatches actions', done => {
        state.selectedTemplateType = { key: 'licenses' };

        testAction(
          actions.fetchTemplateTypes,
          null,
          state,
          [],
          [{ type: 'requestTemplateTypes' }, { type: 'receiveTemplateTypesError' }],
          done,
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
    it('dispatches setErrorMessage', done => {
      testAction(
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
        done,
      );
    });
  });

  describe('fetchTemplate', () => {
    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet(/api\/(.*)\/templates\/licenses\/mit/)
          .replyOnce(200, { content: 'MIT content' });
        mock
          .onGet(/api\/(.*)\/templates\/licenses\/testing/)
          .replyOnce(200, { content: 'testing content' });
      });

      it('dispatches setFileTemplate if template already has content', done => {
        const template = { content: 'already has content' };

        testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'setFileTemplate', payload: template }],
          done,
        );
      });

      it('dispatches success', done => {
        const template = { key: 'mit' };

        state.selectedTemplateType = { key: 'licenses' };

        testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'setFileTemplate', payload: { content: 'MIT content' } }],
          done,
        );
      });

      it('dispatches success and uses name key for API call', done => {
        const template = { name: 'testing' };

        state.selectedTemplateType = { key: 'licenses' };

        testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'setFileTemplate', payload: { content: 'testing content' } }],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/templates\/licenses\/mit/).replyOnce(500);
      });

      it('dispatches error', done => {
        const template = { name: 'testing' };

        state.selectedTemplateType = { key: 'licenses' };

        testAction(
          actions.fetchTemplate,
          template,
          state,
          [],
          [{ type: 'receiveTemplateError', payload: template }],
          done,
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
