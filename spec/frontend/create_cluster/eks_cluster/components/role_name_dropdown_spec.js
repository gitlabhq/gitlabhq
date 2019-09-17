import { shallowMount } from '@vue/test-utils';

import ClusterFormDropdown from '~/create_cluster/eks_cluster/components/cluster_form_dropdown.vue';
import RoleNameDropdown from '~/create_cluster/eks_cluster/components/role_name_dropdown.vue';

describe('RoleNameDropdown', () => {
  let vm;

  beforeEach(() => {
    vm = shallowMount(RoleNameDropdown);
  });
  afterEach(() => vm.destroy());

  it('renders a cluster-form-dropdown', () => {
    expect(vm.find(ClusterFormDropdown).exists()).toBe(true);
  });

  it('sets roles to cluster-form-dropdown items property', () => {
    const roles = [{ name: 'basic' }];

    vm.setProps({ roles });

    expect(vm.find(ClusterFormDropdown).props('items')).toEqual(roles);
  });

  it('sets a loading text', () => {
    expect(vm.find(ClusterFormDropdown).props('loadingText')).toEqual('Loading IAM Roles');
  });

  it('sets a placeholder', () => {
    expect(vm.find(ClusterFormDropdown).props('placeholder')).toEqual('Select role name');
  });

  it('sets an empty results text', () => {
    expect(vm.find(ClusterFormDropdown).props('emptyText')).toEqual('No IAM Roles found');
  });

  it('sets a search field placeholder', () => {
    expect(vm.find(ClusterFormDropdown).props('searchFieldPlaceholder')).toEqual(
      'Search IAM Roles',
    );
  });
});
