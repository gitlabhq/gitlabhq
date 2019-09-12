export default () => ({
  isValidatingCredentials: false,
  validCredentials: false,

  isLoadingRoles: false,
  isLoadingVPCs: false,
  isLoadingSubnets: false,
  isLoadingSecurityGroups: false,

  roles: [],
  vpcs: [],
  subnets: [],
  securityGroups: [],

  selectedRole: '',
  selectedVPC: '',
  selectedSubnet: '',
  selectedSecurityGroup: '',
});
