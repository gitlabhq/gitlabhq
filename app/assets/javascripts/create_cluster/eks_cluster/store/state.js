import { KUBERNETES_VERSIONS } from '../constants';

const kubernetesVersion = KUBERNETES_VERSIONS.find((version) => version.default).value;

export default () => ({
  createRolePath: null,

  isCreatingRole: false,
  roleCreated: false,
  createRoleError: false,

  accountId: '',
  externalId: '',

  roleArn: '',

  clusterName: '',
  environmentScope: '*',
  kubernetesVersion,
  selectedRegion: '',
  selectedRole: '',
  selectedKeyPair: '',
  selectedVpc: '',
  selectedSubnet: [],
  selectedSecurityGroup: '',
  selectedInstanceType: 'm5.large',
  nodeCount: '3',

  isCreatingCluster: false,
  createClusterError: false,

  gitlabManagedCluster: true,
  namespacePerEnvironment: true,
});
