import testAction from 'helpers/vuex_action_helper';
import { setEndpoints } from '~/mr_notes/stores/actions';
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
});
