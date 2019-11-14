import { KUBERNETES_VERSIONS } from '../constants';

const [{ value: kubernetesVersion }] = KUBERNETES_VERSIONS;

export default () => ({
  createRolePath: null,

  isCreatingRole: false,
  roleCreated: false,
  createRoleError: false,

  accountId: '',
  externalId: '',

  clusterName: '',
  environmentScope: '*',
  kubernetesVersion,
  selectedRegion: '',
  selectedRole: '',
  selectedKeyPair: '',
  selectedVpc: '',
  selectedSubnet: '',
  selectedSecurityGroup: '',
  selectedInstanceType: 'm5.large',
  nodeCount: '3',

  isCreatingCluster: false,
  createClusterError: false,

  gitlabManagedCluster: true,
});
