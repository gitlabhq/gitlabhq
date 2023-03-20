import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import testActionFn from './vuex_action_helper';

const testActionFnWithOptionsArg = (...args) => {
  const [action, payload, state, expectedMutations, expectedActions] = args;
  return testActionFn({ action, payload, state, expectedMutations, expectedActions });
};

describe.each([testActionFn, testActionFnWithOptionsArg])(
  'VueX test helper (testAction)',
  (testAction) => {
    let originalExpect;
    let assertion;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      /**
       * In order to test the helper properly, we need to overwrite the Jest
       * `expect` helper.  We test that the testAction helper properly passes the
       * dispatched actions/committed mutations to the Jest helper.
       */
      originalExpect = expect;
      assertion = null;
      global.expect = (actual) => ({
        toEqual: () => {
          originalExpect(actual).toEqual(assertion);
        },
      });
    });

    afterEach(() => {
      mock.restore();
      global.expect = originalExpect;
    });

    it('properly passes state and payload to action', () => {
      const exampleState = { FOO: 12, BAR: 3 };
      const examplePayload = { BAZ: 73, BIZ: 55 };

      const action = ({ state }, payload) => {
        originalExpect(state).toEqual(exampleState);
        originalExpect(payload).toEqual(examplePayload);
      };

      assertion = { mutations: [], actions: [] };

      return testAction(action, examplePayload, exampleState);
    });

    describe('given a sync action', () => {
      it('mocks committing mutations', () => {
        const action = ({ commit }) => {
          commit('MUTATION');
        };

        assertion = { mutations: [{ type: 'MUTATION' }], actions: [] };

        return testAction(action, null, {}, assertion.mutations, assertion.actions);
      });

      it('mocks dispatching actions', () => {
        const action = ({ dispatch }) => {
          dispatch('ACTION');
        };

        assertion = { actions: [{ type: 'ACTION' }], mutations: [] };

        return testAction(action, null, {}, assertion.mutations, assertion.actions);
      });

      it('returns a promise', () => {
        assertion = { mutations: [], actions: [] };

        const promise = testAction(() => {}, null, {}, assertion.mutations, assertion.actions);

        originalExpect(promise instanceof Promise).toBe(true);

        return promise;
      });
    });

    describe('given an async action (chaining off a dispatch)', () => {
      it('mocks dispatch accurately', () => {
        const asyncAction = ({ commit, dispatch }) => {
          return dispatch('ACTION').then(() => {
            commit('MUTATION');
          });
        };

        assertion = { actions: [{ type: 'ACTION' }], mutations: [{ type: 'MUTATION' }] };

        return testAction(asyncAction, null, {}, assertion.mutations, assertion.actions);
      });
    });

    describe('given an async action (returning a promise)', () => {
      const data = { FOO: 'BAR' };

      const asyncAction = ({ commit, dispatch }) => {
        dispatch('ACTION');

        return axios
          .get(TEST_HOST)
          .catch((error) => {
            commit('ERROR');
            throw error;
          })
          .then(() => {
            commit('SUCCESS');
            return data;
          });
      };

      it('returns original data of successful promise while checking actions/mutations', async () => {
        mock.onGet(TEST_HOST).replyOnce(HTTP_STATUS_OK, 42);

        assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

        const res = await testAction(asyncAction, null, {}, assertion.mutations, assertion.actions);
        originalExpect(res).toEqual(data);
      });

      it('returns original error of rejected promise while checking actions/mutations', async () => {
        mock.onGet(TEST_HOST).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, '');

        assertion = { mutations: [{ type: 'ERROR' }], actions: [{ type: 'ACTION' }] };

        const err = testAction(asyncAction, null, {}, assertion.mutations, assertion.actions);
        await originalExpect(err).rejects.toEqual(new Error('Request failed with status code 500'));
      });
    });

    it('works with actions not returning promises', () => {
      const data = { FOO: 'BAR' };

      const asyncAction = ({ commit, dispatch }) => {
        dispatch('ACTION');

        axios
          .get(TEST_HOST)
          .then(() => {
            commit('SUCCESS');
            return data;
          })
          .catch((error) => {
            commit('ERROR');
            throw error;
          });
      };

      mock.onGet(TEST_HOST).replyOnce(HTTP_STATUS_OK, 42);

      assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

      return testAction(asyncAction, null, {}, assertion.mutations, assertion.actions);
    });
  },
);
