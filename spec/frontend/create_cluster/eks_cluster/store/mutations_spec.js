import {
  SET_CLUSTER_NAME,
  SET_ENVIRONMENT_SCOPE,
  SET_KUBERNETES_VERSION,
  SET_REGION,
  SET_VPC,
  SET_KEY_PAIR,
  SET_SUBNET,
  SET_ROLE,
  SET_SECURITY_GROUP,
  SET_INSTANCE_TYPE,
  SET_NODE_COUNT,
  SET_GITLAB_MANAGED_CLUSTER,
  REQUEST_CREATE_ROLE,
  CREATE_ROLE_SUCCESS,
  CREATE_ROLE_ERROR,
  REQUEST_CREATE_CLUSTER,
  CREATE_CLUSTER_ERROR,
} from '~/create_cluster/eks_cluster/store/mutation_types';
import createState from '~/create_cluster/eks_cluster/store/state';
import mutations from '~/create_cluster/eks_cluster/store/mutations';

describe('Create EKS cluster store mutations', () => {
  let clusterName;
  let environmentScope;
  let kubernetesVersion;
  let state;
  let region;
  let vpc;
  let subnet;
  let role;
  let keyPair;
  let securityGroup;
  let instanceType;
  let nodeCount;
  let gitlabManagedCluster;

  beforeEach(() => {
    clusterName = 'my cluster';
    environmentScope = 'production';
    kubernetesVersion = '11.1';
    region = { name: 'regions-1' };
    vpc = { name: 'vpc-1' };
    subnet = { name: 'subnet-1' };
    role = { name: 'role-1' };
    keyPair = { name: 'key pair' };
    securityGroup = { name: 'default group' };
    instanceType = 'small-1';
    nodeCount = '5';
    gitlabManagedCluster = false;

    state = createState();
  });

  it.each`
    mutation                      | mutatedProperty            | payload                     | expectedValue           | expectedValueDescription
    ${SET_CLUSTER_NAME}           | ${'clusterName'}           | ${{ clusterName }}          | ${clusterName}          | ${'cluster name'}
    ${SET_ENVIRONMENT_SCOPE}      | ${'environmentScope'}      | ${{ environmentScope }}     | ${environmentScope}     | ${'environment scope'}
    ${SET_KUBERNETES_VERSION}     | ${'kubernetesVersion'}     | ${{ kubernetesVersion }}    | ${kubernetesVersion}    | ${'kubernetes version'}
    ${SET_ROLE}                   | ${'selectedRole'}          | ${{ role }}                 | ${role}                 | ${'selected role payload'}
    ${SET_REGION}                 | ${'selectedRegion'}        | ${{ region }}               | ${region}               | ${'selected region payload'}
    ${SET_KEY_PAIR}               | ${'selectedKeyPair'}       | ${{ keyPair }}              | ${keyPair}              | ${'selected key pair payload'}
    ${SET_VPC}                    | ${'selectedVpc'}           | ${{ vpc }}                  | ${vpc}                  | ${'selected vpc payload'}
    ${SET_SUBNET}                 | ${'selectedSubnet'}        | ${{ subnet }}               | ${subnet}               | ${'selected subnet payload'}
    ${SET_SECURITY_GROUP}         | ${'selectedSecurityGroup'} | ${{ securityGroup }}        | ${securityGroup}        | ${'selected security group payload'}
    ${SET_INSTANCE_TYPE}          | ${'selectedInstanceType'}  | ${{ instanceType }}         | ${instanceType}         | ${'selected instance type payload'}
    ${SET_NODE_COUNT}             | ${'nodeCount'}             | ${{ nodeCount }}            | ${nodeCount}            | ${'node count payload'}
    ${SET_GITLAB_MANAGED_CLUSTER} | ${'gitlabManagedCluster'}  | ${{ gitlabManagedCluster }} | ${gitlabManagedCluster} | ${'gitlab managed cluster'}
  `(`$mutation sets $mutatedProperty to $expectedValueDescription`, data => {
    const { mutation, mutatedProperty, payload, expectedValue } = data;

    mutations[mutation](state, payload);
    expect(state[mutatedProperty]).toBe(expectedValue);
  });

  describe(`mutation ${REQUEST_CREATE_ROLE}`, () => {
    beforeEach(() => {
      mutations[REQUEST_CREATE_ROLE](state);
    });

    it('sets isCreatingRole to true', () => {
      expect(state.isCreatingRole).toBe(true);
    });

    it('sets createRoleError to null', () => {
      expect(state.createRoleError).toBe(null);
    });

    it('sets hasCredentials to false', () => {
      expect(state.hasCredentials).toBe(false);
    });
  });

  describe(`mutation ${CREATE_ROLE_SUCCESS}`, () => {
    beforeEach(() => {
      mutations[CREATE_ROLE_SUCCESS](state);
    });

    it('sets isCreatingRole to false', () => {
      expect(state.isCreatingRole).toBe(false);
    });

    it('sets createRoleError to null', () => {
      expect(state.createRoleError).toBe(null);
    });

    it('sets hasCredentials to false', () => {
      expect(state.hasCredentials).toBe(true);
    });
  });

  describe(`mutation ${CREATE_ROLE_ERROR}`, () => {
    const error = new Error();

    beforeEach(() => {
      mutations[CREATE_ROLE_ERROR](state, { error });
    });

    it('sets isCreatingRole to false', () => {
      expect(state.isCreatingRole).toBe(false);
    });

    it('sets createRoleError to the error object', () => {
      expect(state.createRoleError).toBe(error);
    });

    it('sets hasCredentials to false', () => {
      expect(state.hasCredentials).toBe(false);
    });
  });

  describe(`mutation ${REQUEST_CREATE_CLUSTER}`, () => {
    beforeEach(() => {
      mutations[REQUEST_CREATE_CLUSTER](state);
    });

    it('sets isCreatingCluster to true', () => {
      expect(state.isCreatingCluster).toBe(true);
    });

    it('sets createClusterError to null', () => {
      expect(state.createClusterError).toBe(null);
    });
  });

  describe(`mutation ${CREATE_CLUSTER_ERROR}`, () => {
    const error = new Error();

    beforeEach(() => {
      mutations[CREATE_CLUSTER_ERROR](state, { error });
    });

    it('sets isCreatingRole to false', () => {
      expect(state.isCreatingCluster).toBe(false);
    });

    it('sets createRoleError to the error object', () => {
      expect(state.createClusterError).toBe(error);
    });
  });
});
