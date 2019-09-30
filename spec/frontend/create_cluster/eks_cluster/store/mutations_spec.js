import { SET_REGION } from '~/create_cluster/eks_cluster/store/mutation_types';
import createState from '~/create_cluster/eks_cluster/store/state';
import mutations from '~/create_cluster/eks_cluster/store/mutations';

describe('Create EKS cluster store mutations', () => {
  let state;
  let region;

  beforeEach(() => {
    region = { name: 'regions-1' };
    state = createState();
  });

  it.each`
    mutation      | mutatedProperty     | payload       | expectedValue | expectedValueDescription
    ${SET_REGION} | ${'selectedRegion'} | ${{ region }} | ${region}     | ${'selected region payload'}
  `(`$mutation sets $mutatedProperty to $expectedValueDescription`, data => {
    const { mutation, mutatedProperty, payload, expectedValue } = data;

    mutations[mutation](state, payload);
    expect(state[mutatedProperty]).toBe(expectedValue);
  });
});
