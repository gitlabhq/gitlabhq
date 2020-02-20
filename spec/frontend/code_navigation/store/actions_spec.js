import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import actions from '~/code_navigation/store/actions';
import axios from '~/lib/utils/axios_utils';
import { setCurrentHoverElement, addInteractionClass } from '~/code_navigation/utils';

jest.mock('~/code_navigation/utils');

describe('Code navigation actions', () => {
  describe('setInitialData', () => {
    it('commits SET_INITIAL_DATA', done => {
      testAction(
        actions.setInitialData,
        { projectPath: 'test' },
        {},
        [{ type: 'SET_INITIAL_DATA', payload: { projectPath: 'test' } }],
        [],
        done,
      );
    });
  });

  describe('requestDataError', () => {
    it('commits REQUEST_DATA_ERROR', () =>
      testAction(actions.requestDataError, null, {}, [{ type: 'REQUEST_DATA_ERROR' }], []));
  });

  describe('fetchData', () => {
    let mock;
    const state = {
      projectPath: 'gitlab-org/gitlab',
      commitId: '123',
      blobPath: 'index',
    };
    const apiUrl = '/api/1/projects/gitlab-org%2Fgitlab/commits/123/lsif/info';

    beforeEach(() => {
      window.gon = { api_version: '1' };
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(apiUrl).replyOnce(200, [
          {
            start_line: 0,
            start_char: 0,
            hover: { value: '123' },
          },
          {
            start_line: 1,
            start_char: 0,
            hover: null,
          },
        ]);
      });

      it('commits REQUEST_DATA_SUCCESS with normalized data', done => {
        testAction(
          actions.fetchData,
          null,
          state,
          [
            { type: 'REQUEST_DATA' },
            {
              type: 'REQUEST_DATA_SUCCESS',
              payload: { '0:0': { start_line: 0, start_char: 0, hover: { value: '123' } } },
            },
          ],
          [],
          done,
        );
      });

      it('calls addInteractionClass with data', done => {
        testAction(
          actions.fetchData,
          null,
          state,
          [
            { type: 'REQUEST_DATA' },
            {
              type: 'REQUEST_DATA_SUCCESS',
              payload: { '0:0': { start_line: 0, start_char: 0, hover: { value: '123' } } },
            },
          ],
          [],
        )
          .then(() => {
            expect(addInteractionClass).toHaveBeenCalledWith({
              start_line: 0,
              start_char: 0,
              hover: { value: '123' },
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(apiUrl).replyOnce(500);
      });

      it('dispatches requestDataError', done => {
        testAction(
          actions.fetchData,
          null,
          state,
          [{ type: 'REQUEST_DATA' }],
          [{ type: 'requestDataError' }],
          done,
        );
      });
    });
  });

  describe('showDefinition', () => {
    let target;

    beforeEach(() => {
      target = document.createElement('div');
    });

    it('returns early when no data exists', done => {
      testAction(actions.showDefinition, { target }, {}, [], [], done);
    });

    it('commits SET_CURRENT_DEFINITION when target is not code navitation element', done => {
      testAction(
        actions.showDefinition,
        { target },
        { data: {} },
        [
          {
            type: 'SET_CURRENT_DEFINITION',
            payload: { definition: undefined, position: undefined },
          },
        ],
        [],
        done,
      );
    });

    it('commits SET_CURRENT_DEFINITION with LSIF data', done => {
      target.classList.add('js-code-navigation');
      target.setAttribute('data-line-index', '0');
      target.setAttribute('data-char-index', '0');

      testAction(
        actions.showDefinition,
        { target },
        { data: { '0:0': { hover: 'test' } } },
        [
          {
            type: 'SET_CURRENT_DEFINITION',
            payload: { definition: { hover: 'test' }, position: { height: 0, x: 0, y: 0 } },
          },
        ],
        [],
        done,
      );
    });

    it('adds hll class to target element', () => {
      target.classList.add('js-code-navigation');
      target.setAttribute('data-line-index', '0');
      target.setAttribute('data-char-index', '0');

      return testAction(
        actions.showDefinition,
        { target },
        { data: { '0:0': { hover: 'test' } } },
        [
          {
            type: 'SET_CURRENT_DEFINITION',
            payload: { definition: { hover: 'test' }, position: { height: 0, x: 0, y: 0 } },
          },
        ],
        [],
      ).then(() => {
        expect(target.classList).toContain('hll');
      });
    });

    it('caches current target element', () => {
      target.classList.add('js-code-navigation');
      target.setAttribute('data-line-index', '0');
      target.setAttribute('data-char-index', '0');

      return testAction(
        actions.showDefinition,
        { target },
        { data: { '0:0': { hover: 'test' } } },
        [
          {
            type: 'SET_CURRENT_DEFINITION',
            payload: { definition: { hover: 'test' }, position: { height: 0, x: 0, y: 0 } },
          },
        ],
        [],
      ).then(() => {
        expect(setCurrentHoverElement).toHaveBeenCalledWith(target);
      });
    });
  });
});
