import testAction from 'helpers/vuex_action_helper';

import createState from '~/create_cluster/eks_cluster/store/state';
import * as types from '~/create_cluster/eks_cluster/store/mutation_types';
import * as actions from '~/create_cluster/eks_cluster/store/actions';

describe('EKS Cluster Store Actions', () => {
  describe('setRegion', () => {
    it(`commits ${types.SET_REGION} mutation`, () => {
      const region = { name: 'west-1' };

      testAction(actions.setRegion, { region }, createState(), [
        { type: types.SET_REGION, payload: { region } },
      ]);
    });
  });
});
