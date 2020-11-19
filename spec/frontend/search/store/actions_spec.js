import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/search/store/actions';
import * as types from '~/search/store/mutation_types';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import state from '~/search/store/state';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { MOCK_GROUPS } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  setUrlParams: jest.fn(),
  visitUrl: jest.fn(),
  joinPaths: jest.fn(), // For the axios specs
}));

describe('Global Search Store Actions', () => {
  let mock;

  const noCallback = () => {};
  const flashCallback = () => {
    expect(createFlash).toHaveBeenCalledTimes(1);
    createFlash.mockClear();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    action                 | axiosMock                                           | type         | mutationCalls                                                                                     | callback
    ${actions.fetchGroups} | ${{ method: 'onGet', code: 200, res: MOCK_GROUPS }} | ${'success'} | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_SUCCESS, payload: MOCK_GROUPS }]} | ${noCallback}
    ${actions.fetchGroups} | ${{ method: 'onGet', code: 500, res: null }}        | ${'error'}   | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_ERROR }]}                         | ${flashCallback}
  `(`axios calls`, ({ action, axiosMock, type, mutationCalls, callback }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction(action, null, state, mutationCalls, []).then(() => callback());
        });
      });
    });
  });

  describe('setQuery', () => {
    const payload = { key: 'key1', value: 'value1' };

    it('calls the SET_QUERY mutation', done => {
      testAction(actions.setQuery, payload, state, [{ type: types.SET_QUERY, payload }], [], done);
    });
  });

  describe('applyQuery', () => {
    it('calls visitUrl and setParams with the state.query', () => {
      testAction(actions.applyQuery, null, state, [], [], () => {
        expect(setUrlParams).toHaveBeenCalledWith({ ...state.query, page: null });
        expect(visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('resetQuery', () => {
    it('calls visitUrl and setParams with empty values', () => {
      testAction(actions.resetQuery, null, state, [], [], () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          ...state.query,
          page: null,
          state: null,
          confidential: null,
        });
        expect(visitUrl).toHaveBeenCalled();
      });
    });
  });
});

describe('setQuery', () => {
  const payload = { key: 'key1', value: 'value1' };

  it('calls the SET_QUERY mutation', done => {
    testAction(actions.setQuery, payload, state, [{ type: types.SET_QUERY, payload }], [], done);
  });
});
