import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as types from '~/projects/commits/store/mutation_types';
import actions from '~/projects/commits/store/actions';
import createState from '~/projects/commits/store/state';
import { deprecatedCreateFlash as createFlash } from '~/flash';

jest.mock('~/flash');

describe('Project commits actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setInitialData', () => {
    it(`commits ${types.SET_INITIAL_DATA}`, () =>
      testAction(actions.setInitialData, undefined, state, [{ type: types.SET_INITIAL_DATA }]));
  });

  describe('receiveAuthorsSuccess', () => {
    it(`commits ${types.COMMITS_AUTHORS}`, () =>
      testAction(actions.receiveAuthorsSuccess, undefined, state, [
        { type: types.COMMITS_AUTHORS },
      ]));
  });

  describe('shows a flash message when there is an error', () => {
    it('creates a flash', () => {
      const mockDispatchContext = { dispatch: () => {}, commit: () => {}, state };
      actions.receiveAuthorsError(mockDispatchContext);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith('An error occurred fetching the project authors.');
    });
  });

  describe('fetchAuthors', () => {
    it('dispatches request/receive', () => {
      const path = '/-/autocomplete/users.json';
      state.projectId = '8';
      const data = [{ id: 1 }];

      mock.onGet(path).replyOnce(200, data);
      testAction(
        actions.fetchAuthors,
        null,
        state,
        [],
        [{ type: 'receiveAuthorsSuccess', payload: data }],
      );
    });

    it('dispatches request/receive on error', () => {
      const path = '/-/autocomplete/users.json';
      mock.onGet(path).replyOnce(500);

      testAction(actions.fetchAuthors, null, state, [], [{ type: 'receiveAuthorsError' }]);
    });
  });
});
