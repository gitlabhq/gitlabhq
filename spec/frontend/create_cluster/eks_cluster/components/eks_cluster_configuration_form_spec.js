import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import { GlFormCheckbox } from '@gitlab/ui';

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
  let rolesState;
  let regionsState;
  let vpcsState;
  let subnetsState;
  let keyPairsState;
  let securityGroupsState;
  let vpcsActions;
  let rolesActions;
  let regionsActions;
  let subnetsActions;
  let keyPairsActions;
  let securityGroupsActions;
  let vm;

  beforeEach(() => {
    state = eksClusterFormState();
    actions = {
      setClusterName: jest.fn(),
      setEnvironmentScope: jest.fn(),
      setKubernetesVersion: jest.fn(),
      setRegion: jest.fn(),
      setVpc: jest.fn(),
      setSubnet: jest.fn(),
      setRole: jest.fn(),
      setKeyPair: jest.fn(),
      setSecurityGroup: jest.fn(),
      setGitlabManagedCluster: jest.fn(),
    };
    regionsActions = {
      fetchItems: jest.fn(),
    };
    keyPairsActions = {
      fetchItems: jest.fn(),
    };
    vpcsActions = {
      fetchItems: jest.fn(),
    };
    subnetsActions = {
      fetchItems: jest.fn(),
    };
    rolesActions = {
      fetchItems: jest.fn(),
    };
    securityGroupsActions = {
      fetchItems: jest.fn(),
    };
    rolesState = {
      ...clusterDropdownStoreState(),
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
    keyPairsState = {
      ...clusterDropdownStoreState(),
    };
    securityGroupsState = {
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
        roles: {
          namespaced: true,
          state: rolesState,
          actions: rolesActions,
        },
        keyPairs: {
          namespaced: true,
          state: keyPairsState,
          actions: keyPairsActions,
        },
        securityGroups: {
          namespaced: true,
          state: securityGroupsState,
          actions: securityGroupsActions,
        },
      },
    });
  });

  beforeEach(() => {
    vm = shallowMount(EksClusterConfigurationForm, {
      localVue,
      store,
      propsData: {
        gitlabManagedClusterHelpPath: '',
        kubernetesIntegrationHelpPath: '',
      },
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  const findClusterNameInput = () => vm.find('[id=eks-cluster-name]');
  const findEnvironmentScopeInput = () => vm.find('[id=eks-environment-scope]');
  const findKubernetesVersionDropdown = () => vm.find('[field-id="eks-kubernetes-version"]');
  const findRegionDropdown = () => vm.find(RegionDropdown);
  const findKeyPairDropdown = () => vm.find('[field-id="eks-key-pair"]');
  const findVpcDropdown = () => vm.find('[field-id="eks-vpc"]');
  const findSubnetDropdown = () => vm.find('[field-id="eks-subnet"]');
  const findRoleDropdown = () => vm.find('[field-id="eks-role"]');
  const findSecurityGroupDropdown = () => vm.find('[field-id="eks-security-group"]');
  const findGitlabManagedClusterCheckbox = () => vm.find(GlFormCheckbox);

  describe('when mounted', () => {
    it('fetches available regions', () => {
      expect(regionsActions.fetchItems).toHaveBeenCalled();
    });

    it('fetches available roles', () => {
      expect(rolesActions.fetchItems).toHaveBeenCalled();
    });
  });

  it('sets isLoadingRoles to RoleDropdown loading property', () => {
    rolesState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findRoleDropdown().props('loading')).toBe(rolesState.isLoadingItems);
    });
  });

  it('sets roles to RoleDropdown items property', () => {
    expect(findRoleDropdown().props('items')).toBe(rolesState.items);
  });

  it('sets RoleDropdown hasErrors to true when loading roles failed', () => {
    rolesState.loadingItemsError = new Error();

    expect(findRoleDropdown().props('hasErrors')).toEqual(true);
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

  it('disables KeyPairDropdown when no region is selected', () => {
    expect(findKeyPairDropdown().props('disabled')).toBe(true);
  });

  it('enables KeyPairDropdown when no region is selected', () => {
    state.selectedRegion = { name: 'west-1 ' };

    return Vue.nextTick().then(() => {
      expect(findKeyPairDropdown().props('disabled')).toBe(false);
    });
  });

  it('sets isLoadingKeyPairs to KeyPairDropdown loading property', () => {
    keyPairsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findKeyPairDropdown().props('loading')).toBe(keyPairsState.isLoadingItems);
    });
  });

  it('sets keyPairs to KeyPairDropdown items property', () => {
    expect(findKeyPairDropdown().props('items')).toBe(keyPairsState.items);
  });

  it('sets KeyPairDropdown hasErrors to true when loading key pairs fails', () => {
    keyPairsState.loadingItemsError = new Error();

    expect(findKeyPairDropdown().props('hasErrors')).toEqual(true);
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

  it('sets VpcDropdown hasErrors to true when loading vpcs fails', () => {
    vpcsState.loadingItemsError = new Error();

    expect(findVpcDropdown().props('hasErrors')).toEqual(true);
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

  it('sets SubnetDropdown hasErrors to true when loading subnets fails', () => {
    subnetsState.loadingItemsError = new Error();

    expect(findSubnetDropdown().props('hasErrors')).toEqual(true);
  });

  it('disables SecurityGroupDropdown when no vpc is selected', () => {
    expect(findSecurityGroupDropdown().props('disabled')).toBe(true);
  });

  it('enables SecurityGroupDropdown when a vpc is selected', () => {
    state.selectedVpc = { name: 'vpc-1 ' };

    return Vue.nextTick().then(() => {
      expect(findSecurityGroupDropdown().props('disabled')).toBe(false);
    });
  });

  it('sets isLoadingSecurityGroups to SecurityGroupDropdown loading property', () => {
    securityGroupsState.isLoadingItems = true;

    return Vue.nextTick().then(() => {
      expect(findSecurityGroupDropdown().props('loading')).toBe(securityGroupsState.isLoadingItems);
    });
  });

  it('sets securityGroups to SecurityGroupDropdown items property', () => {
    expect(findSecurityGroupDropdown().props('items')).toBe(securityGroupsState.items);
  });

  it('sets SecurityGroupDropdown hasErrors to true when loading security groups fails', () => {
    securityGroupsState.loadingItemsError = new Error();

    expect(findSecurityGroupDropdown().props('hasErrors')).toEqual(true);
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

    it('fetches available key pairs', () => {
      expect(keyPairsActions.fetchItems).toHaveBeenCalledWith(
        expect.anything(),
        { region },
        undefined,
      );
    });
  });

  it('dispatches setClusterName when cluster name input changes', () => {
    const clusterName = 'name';

    findClusterNameInput().vm.$emit('input', clusterName);

    expect(actions.setClusterName).toHaveBeenCalledWith(
      expect.anything(),
      { clusterName },
      undefined,
    );
  });

  it('dispatches setEnvironmentScope when environment scope input changes', () => {
    const environmentScope = 'production';

    findEnvironmentScopeInput().vm.$emit('input', environmentScope);

    expect(actions.setEnvironmentScope).toHaveBeenCalledWith(
      expect.anything(),
      { environmentScope },
      undefined,
    );
  });

  it('dispatches setKubernetesVersion when kubernetes version dropdown changes', () => {
    const kubernetesVersion = { name: '1.11' };

    findKubernetesVersionDropdown().vm.$emit('input', kubernetesVersion);

    expect(actions.setKubernetesVersion).toHaveBeenCalledWith(
      expect.anything(),
      { kubernetesVersion },
      undefined,
    );
  });

  it('dispatches setGitlabManagedCluster when gitlab managed cluster input changes', () => {
    const gitlabManagedCluster = false;

    findGitlabManagedClusterCheckbox().vm.$emit('input', gitlabManagedCluster);

    expect(actions.setGitlabManagedCluster).toHaveBeenCalledWith(
      expect.anything(),
      { gitlabManagedCluster },
      undefined,
    );
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

    it('dispatches fetchSecurityGroups action', () => {
      expect(securityGroupsActions.fetchItems).toHaveBeenCalledWith(
        expect.anything(),
        { vpc },
        undefined,
      );
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

  describe('when role is selected', () => {
    const role = { name: 'admin' };

    beforeEach(() => {
      findRoleDropdown().vm.$emit('input', role);
    });

    it('dispatches setRole action', () => {
      expect(actions.setRole).toHaveBeenCalledWith(expect.anything(), { role }, undefined);
    });
  });

  describe('when key pair is selected', () => {
    const keyPair = { name: 'key pair' };

    beforeEach(() => {
      findKeyPairDropdown().vm.$emit('input', keyPair);
    });

    it('dispatches setKeyPair action', () => {
      expect(actions.setKeyPair).toHaveBeenCalledWith(expect.anything(), { keyPair }, undefined);
    });
  });

  describe('when security group is selected', () => {
    const securityGroup = { name: 'default group' };

    beforeEach(() => {
      findSecurityGroupDropdown().vm.$emit('input', securityGroup);
    });

    it('dispatches setSecurityGroup action', () => {
      expect(actions.setSecurityGroup).toHaveBeenCalledWith(
        expect.anything(),
        { securityGroup },
        undefined,
      );
    });
  });
});
