import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import EksClusterConfigurationForm from '~/create_cluster/eks_cluster/components/eks_cluster_configuration_form.vue';
import eksClusterFormState from '~/create_cluster/eks_cluster/store/state';
import clusterDropdownStoreState from '~/create_cluster/store/cluster_dropdown/state';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EksClusterConfigurationForm', () => {
  let store;
  let actions;
  let getters;
  let state;
  let rolesState;
  let vpcsState;
  let subnetsState;
  let keyPairsState;
  let securityGroupsState;
  let instanceTypesState;
  let vpcsActions;
  let rolesActions;
  let subnetsActions;
  let keyPairsActions;
  let securityGroupsActions;
  let vm;

  const createStore = (config = {}) => {
    actions = {
      createCluster: jest.fn(),
      setClusterName: jest.fn(),
      setEnvironmentScope: jest.fn(),
      setKubernetesVersion: jest.fn(),
      setRegion: jest.fn(),
      setVpc: jest.fn(),
      setSubnet: jest.fn(),
      setRole: jest.fn(),
      setKeyPair: jest.fn(),
      setSecurityGroup: jest.fn(),
      setInstanceType: jest.fn(),
      setNodeCount: jest.fn(),
      setGitlabManagedCluster: jest.fn(),
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
    state = {
      ...eksClusterFormState(),
      ...config.initialState,
    };
    rolesState = {
      ...clusterDropdownStoreState(),
      ...config.rolesState,
    };
    vpcsState = {
      ...clusterDropdownStoreState(),
      ...config.vpcsState,
    };
    subnetsState = {
      ...clusterDropdownStoreState(),
      ...config.subnetsState,
    };
    keyPairsState = {
      ...clusterDropdownStoreState(),
      ...config.keyPairsState,
    };
    securityGroupsState = {
      ...clusterDropdownStoreState(),
      ...config.securityGroupsState,
    };
    instanceTypesState = {
      ...clusterDropdownStoreState(),
      ...config.instanceTypesState,
    };
    getters = {
      subnetValid: config?.getters?.subnetValid || (() => false),
    };
    store = new Vuex.Store({
      state,
      getters,
      actions,
      modules: {
        vpcs: {
          namespaced: true,
          state: vpcsState,
          actions: vpcsActions,
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
        instanceTypes: {
          namespaced: true,
          state: instanceTypesState,
        },
      },
    });
  };

  const createValidStateStore = (initialState) => {
    createStore({
      initialState: {
        clusterName: 'cluster name',
        environmentScope: '*',
        kubernetesVersion: '1.16',
        selectedRegion: 'region',
        selectedRole: 'role',
        selectedKeyPair: 'key pair',
        selectedVpc: 'vpc',
        selectedSubnet: ['subnet 1', 'subnet 2'],
        selectedSecurityGroup: 'group',
        selectedInstanceType: 'small-1',
        ...initialState,
      },
      getters: {
        subnetValid: () => true,
      },
    });
  };

  const buildWrapper = () => {
    vm = shallowMount(EksClusterConfigurationForm, {
      localVue,
      store,
      propsData: {
        gitlabManagedClusterHelpPath: '',
        namespacePerEnvironmentHelpPath: '',
        kubernetesIntegrationHelpPath: '',
        externalLinkIcon: '',
      },
    });
  };

  beforeEach(() => {
    createStore();
    buildWrapper();
  });

  afterEach(() => {
    vm.destroy();
  });

  const findCreateClusterButton = () => vm.find('.js-create-cluster');
  const findClusterNameInput = () => vm.find('[id=eks-cluster-name]');
  const findEnvironmentScopeInput = () => vm.find('[id=eks-environment-scope]');
  const findKubernetesVersionDropdown = () => vm.find('[field-id="eks-kubernetes-version"]');
  const findKeyPairDropdown = () => vm.find('[field-id="eks-key-pair"]');
  const findVpcDropdown = () => vm.find('[field-id="eks-vpc"]');
  const findSubnetDropdown = () => vm.find('[field-id="eks-subnet"]');
  const findRoleDropdown = () => vm.find('[field-id="eks-role"]');
  const findSecurityGroupDropdown = () => vm.find('[field-id="eks-security-group"]');
  const findInstanceTypeDropdown = () => vm.find('[field-id="eks-instance-type"');
  const findNodeCountInput = () => vm.find('[id="eks-node-count"]');
  const findGitlabManagedClusterCheckbox = () => vm.find(GlFormCheckbox);

  describe('when mounted', () => {
    it('fetches available roles', () => {
      expect(rolesActions.fetchItems).toHaveBeenCalled();
    });

    describe('when fetching vpcs and key pairs', () => {
      const region = 'us-west-2';

      beforeEach(() => {
        createValidStateStore({ selectedRegion: region });
        buildWrapper();
      });

      it('fetches available vpcs', () => {
        expect(vpcsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), { region });
      });

      it('fetches available key pairs', () => {
        expect(keyPairsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), { region });
      });

      it('cleans selected vpc', () => {
        expect(actions.setVpc).toHaveBeenCalledWith(expect.anything(), { vpc: null });
      });

      it('cleans selected key pair', () => {
        expect(actions.setKeyPair).toHaveBeenCalledWith(expect.anything(), { keyPair: null });
      });

      it('cleans selected subnet', () => {
        expect(actions.setSubnet).toHaveBeenCalledWith(expect.anything(), { subnet: [] });
      });

      it('cleans selected security group', () => {
        expect(actions.setSecurityGroup).toHaveBeenCalledWith(expect.anything(), {
          securityGroup: null,
        });
      });
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

    return Vue.nextTick().then(() => {
      expect(findRoleDropdown().props('hasErrors')).toEqual(true);
    });
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

    return Vue.nextTick().then(() => {
      expect(findKeyPairDropdown().props('hasErrors')).toEqual(true);
    });
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

    return Vue.nextTick().then(() => {
      expect(findVpcDropdown().props('hasErrors')).toEqual(true);
    });
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

  it('displays a validation error in the subnet dropdown when loading subnets fails', () => {
    createStore({
      subnetsState: {
        loadingItemsError: new Error(),
      },
    });
    buildWrapper();

    expect(findSubnetDropdown().props('hasErrors')).toEqual(true);
  });

  it('displays a validation error in the subnet dropdown  when a single subnet is selected', () => {
    createStore({
      initialState: {
        selectedSubnet: ['subnet 1'],
      },
    });
    buildWrapper();

    expect(findSubnetDropdown().props('hasErrors')).toEqual(true);
    expect(findSubnetDropdown().props('errorMessage')).toEqual(
      'You should select at least two subnets',
    );
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

    return Vue.nextTick().then(() => {
      expect(findSecurityGroupDropdown().props('hasErrors')).toEqual(true);
    });
  });

  it('dispatches setClusterName when cluster name input changes', () => {
    const clusterName = 'name';

    findClusterNameInput().vm.$emit('input', clusterName);

    expect(actions.setClusterName).toHaveBeenCalledWith(expect.anything(), { clusterName });
  });

  it('dispatches setEnvironmentScope when environment scope input changes', () => {
    const environmentScope = 'production';

    findEnvironmentScopeInput().vm.$emit('input', environmentScope);

    expect(actions.setEnvironmentScope).toHaveBeenCalledWith(expect.anything(), {
      environmentScope,
    });
  });

  it('dispatches setKubernetesVersion when kubernetes version dropdown changes', () => {
    const kubernetesVersion = { name: '1.11' };

    findKubernetesVersionDropdown().vm.$emit('input', kubernetesVersion);

    expect(actions.setKubernetesVersion).toHaveBeenCalledWith(expect.anything(), {
      kubernetesVersion,
    });
  });

  it('dispatches setGitlabManagedCluster when gitlab managed cluster input changes', () => {
    const gitlabManagedCluster = false;

    findGitlabManagedClusterCheckbox().vm.$emit('input', gitlabManagedCluster);

    expect(actions.setGitlabManagedCluster).toHaveBeenCalledWith(expect.anything(), {
      gitlabManagedCluster,
    });
  });

  describe('when vpc is selected', () => {
    const vpc = { name: 'vpc-1' };
    const region = 'east-1';

    beforeEach(() => {
      state.selectedRegion = region;
      findVpcDropdown().vm.$emit('input', vpc);
    });

    it('dispatches setVpc action', () => {
      expect(actions.setVpc).toHaveBeenCalledWith(expect.anything(), { vpc });
    });

    it('cleans selected subnet', () => {
      expect(actions.setSubnet).toHaveBeenCalledWith(expect.anything(), { subnet: [] });
    });

    it('cleans selected security group', () => {
      expect(actions.setSecurityGroup).toHaveBeenCalledWith(expect.anything(), {
        securityGroup: null,
      });
    });

    it('dispatches fetchSubnets action', () => {
      expect(subnetsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), { vpc, region });
    });

    it('dispatches fetchSecurityGroups action', () => {
      expect(securityGroupsActions.fetchItems).toHaveBeenCalledWith(expect.anything(), {
        vpc,
        region,
      });
    });
  });

  describe('when a subnet is selected', () => {
    const subnet = { name: 'subnet-1' };

    beforeEach(() => {
      findSubnetDropdown().vm.$emit('input', subnet);
    });

    it('dispatches setSubnet action', () => {
      expect(actions.setSubnet).toHaveBeenCalledWith(expect.anything(), { subnet });
    });
  });

  describe('when role is selected', () => {
    const role = { name: 'admin' };

    beforeEach(() => {
      findRoleDropdown().vm.$emit('input', role);
    });

    it('dispatches setRole action', () => {
      expect(actions.setRole).toHaveBeenCalledWith(expect.anything(), { role });
    });
  });

  describe('when key pair is selected', () => {
    const keyPair = { name: 'key pair' };

    beforeEach(() => {
      findKeyPairDropdown().vm.$emit('input', keyPair);
    });

    it('dispatches setKeyPair action', () => {
      expect(actions.setKeyPair).toHaveBeenCalledWith(expect.anything(), { keyPair });
    });
  });

  describe('when security group is selected', () => {
    const securityGroup = { name: 'default group' };

    beforeEach(() => {
      findSecurityGroupDropdown().vm.$emit('input', securityGroup);
    });

    it('dispatches setSecurityGroup action', () => {
      expect(actions.setSecurityGroup).toHaveBeenCalledWith(expect.anything(), { securityGroup });
    });
  });

  describe('when instance type is selected', () => {
    const instanceType = 'small-1';

    beforeEach(() => {
      findInstanceTypeDropdown().vm.$emit('input', instanceType);
    });

    it('dispatches setInstanceType action', () => {
      expect(actions.setInstanceType).toHaveBeenCalledWith(expect.anything(), { instanceType });
    });
  });

  it('dispatches setNodeCount when node count input changes', () => {
    const nodeCount = 5;

    findNodeCountInput().vm.$emit('input', nodeCount);

    expect(actions.setNodeCount).toHaveBeenCalledWith(expect.anything(), { nodeCount });
  });

  describe('when all cluster configuration fields are set', () => {
    it('enables create cluster button', () => {
      createValidStateStore();
      buildWrapper();
      expect(findCreateClusterButton().props('disabled')).toBe(false);
    });
  });

  describe('when at least one cluster configuration field is not set', () => {
    beforeEach(() => {
      createValidStateStore({
        clusterName: null,
      });
      buildWrapper();
    });

    it('disables create cluster button', () => {
      expect(findCreateClusterButton().props('disabled')).toBe(true);
    });
  });

  describe('when is creating cluster', () => {
    beforeEach(() => {
      createValidStateStore({
        isCreatingCluster: true,
      });
      buildWrapper();
    });

    it('sets create cluster button as loading', () => {
      expect(findCreateClusterButton().props('loading')).toBe(true);
    });
  });

  describe('clicking create cluster button', () => {
    beforeEach(() => {
      findCreateClusterButton().vm.$emit('click');
    });

    it('dispatches createCluster action', () => {
      expect(actions.createCluster).toHaveBeenCalled();
    });
  });
});
