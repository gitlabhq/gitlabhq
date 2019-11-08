import { KUBERNETES_VERSIONS } from '../constants';

export default () => ({
  createRolePath: null,

  isCreatingRole: false,
  roleCreated: false,
  createRoleError: false,

  accountId: '',
  externalId: '',

  clusterName: '',
  environmentScope: '*',
  kubernetesVersion: [KUBERNETES_VERSIONS].value,
  selectedRegion: '',
  selectedRole: '',
  selectedKeyPair: '',
  selectedVpc: '',
  selectedSubnet: '',
  selectedSecurityGroup: '',

  gitlabManagedCluster: true,
});
