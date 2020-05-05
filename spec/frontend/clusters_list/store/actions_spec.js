import MockAdapter from 'axios-mock-adapter';
import flashError from '~/flash';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import * as types from '~/clusters_list/store/mutation_types';
import * as actions from '~/clusters_list/store/actions';

jest.mock('~/flash.js');

describe('Clusters store actions', () => {
  describe('fetchClusters', () => {
    let mock;
    const endpoint = '/clusters';
    const clusters = [{ name: 'test' }];

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('should commit SET_CLUSTERS_DATA with received response', done => {
      mock.onGet().reply(200, clusters);

      testAction(
        actions.fetchClusters,
        { endpoint },
        {},
        [
          { type: types.SET_CLUSTERS_DATA, payload: clusters },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
        () => done(),
      );
    });

    it('should show flash on API error', done => {
      mock.onGet().reply(400, 'Not Found');

      testAction(actions.fetchClusters, { endpoint }, {}, [], [], () => {
        expect(flashError).toHaveBeenCalledWith(expect.stringMatching('error'));
        done();
      });
    });
  });
});
