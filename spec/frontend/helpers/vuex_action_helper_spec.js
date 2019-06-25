import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import testAction from './vuex_action_helper';

describe('VueX test helper (testAction)', () => {
  let originalExpect;
  let assertion;
  let mock;
  const noop = () => {};

  beforeEach(() => {
    mock = new MockAdapter(axios);
    /**
     * In order to test the helper properly, we need to overwrite the Jest
     * `expect` helper.  We test that the testAction helper properly passes the
     * dispatched actions/committed mutations to the Jest helper.
     */
    originalExpect = expect;
    assertion = null;
    global.expect = actual => ({
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

    testAction(action, examplePayload, exampleState);
  });

  describe('given a sync action', () => {
    it('mocks committing mutations', () => {
      const action = ({ commit }) => {
        commit('MUTATION');
      };

      assertion = { mutations: [{ type: 'MUTATION' }], actions: [] };

      testAction(action, null, {}, assertion.mutations, assertion.actions, noop);
    });

    it('mocks dispatching actions', () => {
      const action = ({ dispatch }) => {
        dispatch('ACTION');
      };

      assertion = { actions: [{ type: 'ACTION' }], mutations: [] };

      testAction(action, null, {}, assertion.mutations, assertion.actions, noop);
    });

    it('works with done callback once finished', done => {
      assertion = { mutations: [], actions: [] };

      testAction(noop, null, {}, assertion.mutations, assertion.actions, done);
    });

    it('returns a promise', done => {
      assertion = { mutations: [], actions: [] };

      testAction(noop, null, {}, assertion.mutations, assertion.actions)
        .then(done)
        .catch(done.fail);
    });
  });

  describe('given an async action (returning a promise)', () => {
    let lastError;
    const data = { FOO: 'BAR' };

    const asyncAction = ({ commit, dispatch }) => {
      dispatch('ACTION');

      return axios
        .get(TEST_HOST)
        .catch(error => {
          commit('ERROR');
          lastError = error;
          throw error;
        })
        .then(() => {
          commit('SUCCESS');
          return data;
        });
    };

    beforeEach(() => {
      lastError = null;
    });

    it('works with done callback once finished', done => {
      mock.onGet(TEST_HOST).replyOnce(200, 42);

      assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

      testAction(asyncAction, null, {}, assertion.mutations, assertion.actions, done);
    });

    it('returns original data of successful promise while checking actions/mutations', done => {
      mock.onGet(TEST_HOST).replyOnce(200, 42);

      assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

      testAction(asyncAction, null, {}, assertion.mutations, assertion.actions)
        .then(res => {
          originalExpect(res).toEqual(data);
          done();
        })
        .catch(done.fail);
    });

    it('returns original error of rejected promise while checking actions/mutations', done => {
      mock.onGet(TEST_HOST).replyOnce(500, '');

      assertion = { mutations: [{ type: 'ERROR' }], actions: [{ type: 'ACTION' }] };

      testAction(asyncAction, null, {}, assertion.mutations, assertion.actions)
        .then(done.fail)
        .catch(error => {
          originalExpect(error).toBe(lastError);
          done();
        });
    });
  });

  it('works with async actions not returning promises', done => {
    const data = { FOO: 'BAR' };

    const asyncAction = ({ commit, dispatch }) => {
      dispatch('ACTION');

      axios
        .get(TEST_HOST)
        .then(() => {
          commit('SUCCESS');
          return data;
        })
        .catch(error => {
          commit('ERROR');
          throw error;
        });
    };

    mock.onGet(TEST_HOST).replyOnce(200, 42);

    assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

    testAction(asyncAction, null, {}, assertion.mutations, assertion.actions, done);
  });
});
