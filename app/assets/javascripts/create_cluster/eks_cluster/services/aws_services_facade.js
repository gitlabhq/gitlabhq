import axios from '~/lib/utils/axios_utils';

export default apiPaths => ({
  fetchRoles() {
    return axios
      .get(apiPaths.getRolesPath)
      .then(({ data: { roles } }) =>
        roles.map(({ role_name: name, arn: value }) => ({ name, value })),
      );
  },
  fetchKeyPairs({ region }) {
    return axios
      .get(apiPaths.getKeyPairsPath, { params: { region } })
      .then(({ data: { key_pairs: keyPairs } }) =>
        keyPairs.map(({ key_name }) => ({ name: key_name, value: key_name })),
      );
  },
  fetchRegions() {
    return axios.get(apiPaths.getRegionsPath).then(({ data: { regions } }) =>
      regions.map(({ region_name }) => ({
        name: region_name,
        value: region_name,
      })),
    );
  },
  fetchVpcs({ region }) {
    return axios.get(apiPaths.getVpcsPath, { params: { region } }).then(({ data: { vpcs } }) =>
      vpcs.map(({ vpc_id }) => ({
        value: vpc_id,
        name: vpc_id,
      })),
    );
  },
  fetchSubnets({ vpc, region }) {
    return axios
      .get(apiPaths.getSubnetsPath, { params: { vpc_id: vpc, region } })
      .then(({ data: { subnets } }) =>
        subnets.map(({ subnet_id }) => ({ name: subnet_id, value: subnet_id })),
      );
  },
  fetchSecurityGroups({ vpc, region }) {
    return axios
      .get(apiPaths.getSecurityGroupsPath, { params: { vpc_id: vpc, region } })
      .then(({ data: { security_groups: securityGroups } }) =>
        securityGroups.map(({ group_name: name, group_id: value }) => ({ name, value })),
      );
  },
  fetchInstanceTypes() {
    return axios
      .get(apiPaths.getInstanceTypesPath)
      .then(({ data: { instance_types: instanceTypes } }) =>
        instanceTypes.map(({ instance_type_name }) => ({
          name: instance_type_name,
          value: instance_type_name,
        })),
      );
  },
});
