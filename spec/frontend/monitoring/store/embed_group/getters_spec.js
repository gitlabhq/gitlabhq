import { metricsWithData } from '~/monitoring/stores/embed_group/getters';
import { mockNamespaces } from '../../mock_data';

describe('Embed group getters', () => {
  describe('metricsWithData', () => {
    it('correctly sums the number of metrics with data', () => {
      const mockMetric = {};
      const state = {
        modules: mockNamespaces,
      };
      const rootGetters = {
        [`${mockNamespaces[0]}/metricsWithData`]: () => [mockMetric],
        [`${mockNamespaces[1]}/metricsWithData`]: () => [mockMetric, mockMetric],
      };

      expect(metricsWithData(state, null, null, rootGetters)).toEqual([1, 2]);
    });
  });
});
