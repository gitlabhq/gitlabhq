import MockAdapter from 'axios-mock-adapter';

import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';

import { setEndpoints, setMrMetadata, fetchMrMetadata } from '~/mr_notes/stores/actions';
import mutationTypes from '~/mr_notes/stores/mutation_types';

describe('MR Notes Mutator Actions', () => {
  describe('setEndpoints', () => {
    it('should trigger the SET_ENDPOINTS state mutation', (done) => {
      const endpoints = { endpointA: 'a' };

      testAction(
        setEndpoints,
        endpoints,
        {},
        [
          {
            type: mutationTypes.SET_ENDPOINTS,
            payload: endpoints,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setMrMetadata', () => {
    it('should trigger the SET_MR_METADATA state mutation', async () => {
      const mrMetadata = { propA: 'a', propB: 'b' };

      await testAction(
        setMrMetadata,
        mrMetadata,
        {},
        [
          {
            type: mutationTypes.SET_MR_METADATA,
            payload: mrMetadata,
          },
        ],
        [],
      );
    });
  });

  describe('fetchMrMetadata', () => {
    const mrMetadata = { meta: true, data: 'foo' };
    const state = {
      endpoints: {
        metadata: 'metadata',
      },
    };
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);

      mock.onGet(state.endpoints.metadata).reply(200, mrMetadata);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should fetch the data from the API', async () => {
      await fetchMrMetadata({ state, dispatch: () => {} });

      await axios.waitForAll();

      expect(mock.history.get).toHaveLength(1);
      expect(mock.history.get[0].url).toBe(state.endpoints.metadata);
    });

    it('should set the fetched data into state', () => {
      return testAction(
        fetchMrMetadata,
        {},
        state,
        [],
        [
          {
            type: 'setMrMetadata',
            payload: mrMetadata,
          },
        ],
      );
    });
  });
});
