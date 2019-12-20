import * as types from './mutation_types';

export default {
  [types.SET_CLUSTER_NAME](state, { clusterName }) {
    state.clusterName = clusterName;
  },
  [types.SET_ENVIRONMENT_SCOPE](state, { environmentScope }) {
    state.environmentScope = environmentScope;
  },
  [types.SET_KUBERNETES_VERSION](state, { kubernetesVersion }) {
    state.kubernetesVersion = kubernetesVersion;
  },
  [types.SET_REGION](state, { region }) {
    state.selectedRegion = region;
  },
  [types.SET_KEY_PAIR](state, { keyPair }) {
    state.selectedKeyPair = keyPair;
  },
  [types.SET_VPC](state, { vpc }) {
    state.selectedVpc = vpc;
  },
  [types.SET_SUBNET](state, { subnet }) {
    state.selectedSubnet = subnet;
  },
  [types.SET_ROLE](state, { role }) {
    state.selectedRole = role;
  },
  [types.SET_SECURITY_GROUP](state, { securityGroup }) {
    state.selectedSecurityGroup = securityGroup;
  },
  [types.SET_INSTANCE_TYPE](state, { instanceType }) {
    state.selectedInstanceType = instanceType;
  },
  [types.SET_NODE_COUNT](state, { nodeCount }) {
    state.nodeCount = nodeCount;
  },
  [types.SET_GITLAB_MANAGED_CLUSTER](state, { gitlabManagedCluster }) {
    state.gitlabManagedCluster = gitlabManagedCluster;
  },
  [types.REQUEST_CREATE_ROLE](state) {
    state.isCreatingRole = true;
    state.createRoleError = null;
    state.hasCredentials = false;
  },
  [types.CREATE_ROLE_SUCCESS](state) {
    state.isCreatingRole = false;
    state.createRoleError = null;
    state.hasCredentials = true;
  },
  [types.CREATE_ROLE_ERROR](state, { error }) {
    state.isCreatingRole = false;
    state.createRoleError = error;
    state.hasCredentials = false;
  },
  [types.REQUEST_CREATE_CLUSTER](state) {
    state.isCreatingCluster = true;
    state.createClusterError = null;
  },
  [types.CREATE_CLUSTER_ERROR](state, { error }) {
    state.isCreatingCluster = false;
    state.createClusterError = error;
  },
};
