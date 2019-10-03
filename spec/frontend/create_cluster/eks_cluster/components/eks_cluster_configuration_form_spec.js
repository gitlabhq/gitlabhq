import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import RegionDropdown from '~/create_cluster/eks_cluster/components/region_dropdown.vue';

import eksClusterFormState from '~/create_cluster/eks_cluster/store/state';
import clusterDropdownStoreState from '~/create_cluster/eks_cluster/store/cluster_dropdown/state';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EksClusterConfigurationForm', () => {
  let store;
  let actions;
  let state;
  let regionsState;
  let vpcsState;
  let subnetsState;
  let vpcsActions;
  let regionsActions;
  let subnetsActions;
  let vm;

  beforeEach(() => {
    state = eksClusterFormState();
    actions = {
      setRegion: jest.fn(),
      setVpc: jest.fn(),
      setSubnet: jest.fn(),
    };
    regionsActions = {
      fetchItems: jest.fn(),
    };
    vpcsActions = {
      fetchItems: jest.fn(),
    };
    subnetsActions = {
      fetchItems: jest.fn(),
    };
    regionsState = {
      ...clusterDropdownStoreState(),
    };
    vpcsState = {
      ...clusterDropdownStoreState(),
    };
    subnetsState = {
      ...clusterDropdownStoreState(),
    };
    store = new Vuex.Store({
      state,
      actions,
      modules: {
        vpcs: {
          namespaced: true,
          state: vpcsState,
          actions: vpcsActions,
        },
        regions: {
          namespaced: true,
          state: regionsState,
          actions: regionsActions,
        },
        subnets: {
          namespaced: true,
          state: subnetsState,
          actions: subnetsActions,
        },
      },
    });
  });

  beforeEach(() => {
    vm = shallowMount(EksClusterConfigurationForm, {
      localVue,
      store,
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  const findRegionDropdown = () => vm.find(RegionDropdown);
  const findVpcDropdown = () => vm.find('[field-id="eks-vpc"]');
  const findSubnetDropdown = () => vm.find('[field-id="eks-subnet"]');

  describe('when mounted', () => {
    it('fetches available regions', () => {
      expect(regionsActions.fetchItems).toHaveBeenCalled();
    });
  });

  it('sets isLoadingRegions to RegionDropdown loading property', () => {
    regionsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findRegionDropdown().props('loading')).toBe(regionsState.isLoadingItems);
    });
  });

  it('sets regions to RegionDropdown regions property', () => {
    expect(findRegionDropdown().props('regions')).toBe(regionsState.items);
  });

  it('sets loadingRegionsError to RegionDropdown error property', () => {
    expect(findRegionDropdown().props('error')).toBe(regionsState.loadingItemsError);
  });

  it('disables VpcDropdown when no region is selected', () => {
    expect(findVpcDropdown().props('disabled')).toBe(true);
  });

  it('enables VpcDropdown when no region is selected', () => {
    state.selectedRegion = { name: 'west-1 ' };

    return Vue.nextTick().then(() => {
      expect(findVpcDropdown().props('disabled')).toBe(false);
    });
  });

  it('sets isLoadingVpcs to VpcDropdown loading property', () => {
    vpcsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findVpcDropdown().props('loading')).toBe(vpcsState.isLoadingItems);
    });
  });

  it('sets vpcs to VpcDropdown items property', () => {
    expect(findVpcDropdown().props('items')).toBe(vpcsState.items);
  });

  it('sets loadingVpcsError to VpcDropdown hasErrors property', () => {
    expect(findVpcDropdown().props('hasErrors')).toBe(vpcsState.loadingItemsError);
  });

  it('disables SubnetDropdown when no vpc is selected', () => {
    expect(findSubnetDropdown().props('disabled')).toBe(true);
  });

  it('enables SubnetDropdown when a vpc is selected', () => {
    state.selectedVpc = { name: 'vpc-1 ' };

    return Vue.nextTick().then(() => {
      expect(findSubnetDropdown().props('disabled')).toBe(false);
    });
  });

  it('sets isLoadingSubnets to SubnetDropdown loading property', () => {
    subnetsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findSubnetDropdown().props('loading')).toBe(subnetsState.isLoadingItems);
    });
  });

  it('sets subnets to SubnetDropdown items property', () => {
    expect(findSubnetDropdown().props('items')).toBe(subnetsState.items);
  });

  it('sets loadingSubnetsError to SubnetDropdown hasErrors property', () => {
    expect(findSubnetDropdown().props('hasErrors')).toBe(subnetsState.loadingItemsError);
  });

  describe('when region is selected', () => {
    const region = { name: 'us-west-2' };

    beforeEach(() => {
      findRegionDropdown().vm.$emit('input', region);
    });

    it('dispatches setRegion action', () => {
      expect(actions.setRegion).toHaveBeenCalledWith(expect.anything(), { region }, undefined);
    });

    it('fetches available vpcs', () => {
      expect(vpcsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), { region }, undefined);
    });
  });

  describe('when vpc is selected', () => {
    const vpc = { name: 'vpc-1' };

    beforeEach(() => {
      findVpcDropdown().vm.$emit('input', vpc);
    });

    it('dispatches setVpc action', () => {
      expect(actions.setVpc).toHaveBeenCalledWith(expect.anything(), { vpc }, undefined);
    });

    it('dispatches fetchSubnets action', () => {
      expect(subnetsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), { vpc }, undefined);
    });
  });

  describe('when a subnet is selected', () => {
    const subnet = { name: 'subnet-1' };

    beforeEach(() => {
      findSubnetDropdown().vm.$emit('input', subnet);
    });

    it('dispatches setSubnet action', () => {
      expect(actions.setSubnet).toHaveBeenCalledWith(expect.anything(), { subnet }, undefined);
    });
  });
});
