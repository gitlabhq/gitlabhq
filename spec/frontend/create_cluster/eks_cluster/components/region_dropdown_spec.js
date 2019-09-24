import { shallowMount } from '@vue/test-utils';

import ClusterFormDropdown from '~/create_cluster/eks_cluster/components/cluster_form_dropdown.vue';
import RegionDropdown from '~/create_cluster/eks_cluster/components/region_dropdown.vue';

describe('RegionDropdown', () => {
  let vm;

  const getClusterFormDropdown = () => vm.find(ClusterFormDropdown);

  beforeEach(() => {
    vm = shallowMount(RegionDropdown);
  });
  afterEach(() => vm.destroy());

  it('renders a cluster-form-dropdown', () => {
    expect(getClusterFormDropdown().exists()).toBe(true);
  });

  it('sets regions to cluster-form-dropdown items property', () => {
    const regions = [{ name: 'basic' }];

    vm.setProps({ regions });

    expect(getClusterFormDropdown().props('items')).toEqual(regions);
  });

  it('sets a loading text', () => {
    expect(getClusterFormDropdown().props('loadingText')).toEqual('Loading Regions');
  });

  it('sets a placeholder', () => {
    expect(getClusterFormDropdown().props('placeholder')).toEqual('Select a region');
  });

  it('sets an empty results text', () => {
    expect(getClusterFormDropdown().props('emptyText')).toEqual('No region found');
  });

  it('sets a search field placeholder', () => {
    expect(getClusterFormDropdown().props('searchFieldPlaceholder')).toEqual('Search regions');
  });

  it('sets hasErrors property', () => {
    vm.setProps({ error: {} });

    expect(getClusterFormDropdown().props('hasErrors')).toEqual(true);
  });

  it('sets an error message', () => {
    expect(getClusterFormDropdown().props('errorMessage')).toEqual(
      'Could not load regions from your AWS account',
    );
  });
});
