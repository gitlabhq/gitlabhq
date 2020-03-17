import { subnetValid } from '~/create_cluster/eks_cluster/store/getters';

describe('EKS Cluster Store Getters', () => {
  describe('subnetValid', () => {
    it('returns true if there are 2 or more selected subnets', () => {
      expect(subnetValid({ selectedSubnet: [1, 2] })).toBe(true);
    });

    it.each([[[], [1]]])('returns false if there are 1 or less selected subnets', subnets => {
      expect(subnetValid({ selectedSubnet: subnets })).toBe(false);
    });
  });
});
