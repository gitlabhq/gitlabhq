export default () => ({
  isValidatingCredentials: false,
  validCredentials: false,

  isLoadingRegions: false,
  isLoadingRoles: false,
  isLoadingVPCs: false,
  isLoadingSubnets: false,
  isLoadingSecurityGroups: false,

  regions: [],
  roles: [],
  vpcs: [],
  subnets: [],
  securityGroups: [],

  loadingRegionsError: null,
  loadingRolesError: null,
  loadingVPCsError: null,
  loadingSubnetsError: null,
  loadingSecurityGroupsError: null,

  selectedRegion: '',
  selectedRole: '',
  selectedVPC: '',
  selectedSubnet: '',
  selectedSecurityGroup: '',
});
