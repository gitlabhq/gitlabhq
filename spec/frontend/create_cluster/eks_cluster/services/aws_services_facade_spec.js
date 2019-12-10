import AxiosMockAdapter from 'axios-mock-adapter';
import awsServicesFacadeFactory from '~/create_cluster/eks_cluster/services/aws_services_facade';
import axios from '~/lib/utils/axios_utils';

describe('awsServicesFacade', () => {
  let apiPaths;
  let axiosMock;
  let awsServices;
  let region;
  let vpc;

  beforeEach(() => {
    apiPaths = {
      getKeyPairsPath: '/clusters/aws/api/key_pairs',
      getRegionsPath: '/clusters/aws/api/regions',
      getRolesPath: '/clusters/aws/api/roles',
      getSecurityGroupsPath: '/clusters/aws/api/security_groups',
      getSubnetsPath: '/clusters/aws/api/subnets',
      getVpcsPath: '/clusters/aws/api/vpcs',
      getInstanceTypesPath: '/clusters/aws/api/instance_types',
    };
    region = 'west-1';
    vpc = 'vpc-2';
    awsServices = awsServicesFacadeFactory(apiPaths);
    axiosMock = new AxiosMockAdapter(axios);
  });

  describe('when fetchRegions succeeds', () => {
    let regions;
    let regionsOutput;

    beforeEach(() => {
      regions = [{ region_name: 'east-1' }, { region_name: 'west-2' }];
      regionsOutput = regions.map(({ region_name: name }) => ({ name, value: name }));
      axiosMock.onGet(apiPaths.getRegionsPath).reply(200, { regions });
    });

    it('return list of roles where each item has a name and value', () => {
      expect(awsServices.fetchRegions()).resolves.toEqual(regionsOutput);
    });
  });

  describe('when fetchRoles succeeds', () => {
    let roles;
    let rolesOutput;

    beforeEach(() => {
      roles = [
        { role_name: 'admin', arn: 'aws::admin' },
        { role_name: 'read-only', arn: 'aws::read-only' },
      ];
      rolesOutput = roles.map(({ role_name: name, arn: value }) => ({ name, value }));
      axiosMock.onGet(apiPaths.getRolesPath).reply(200, { roles });
    });

    it('return list of regions where each item has a name and value', () => {
      expect(awsServices.fetchRoles()).resolves.toEqual(rolesOutput);
    });
  });

  describe('when fetchKeyPairs succeeds', () => {
    let keyPairs;
    let keyPairsOutput;

    beforeEach(() => {
      keyPairs = [{ key_pair: 'key-pair' }, { key_pair: 'key-pair-2' }];
      keyPairsOutput = keyPairs.map(({ key_name: name }) => ({ name, value: name }));
      axiosMock
        .onGet(apiPaths.getKeyPairsPath, { params: { region } })
        .reply(200, { key_pairs: keyPairs });
    });

    it('return list of key pairs where each item has a name and value', () => {
      expect(awsServices.fetchKeyPairs({ region })).resolves.toEqual(keyPairsOutput);
    });
  });

  describe('when fetchVpcs succeeds', () => {
    let vpcs;
    let vpcsOutput;

    beforeEach(() => {
      vpcs = [{ vpc_id: 'vpc-1' }, { vpc_id: 'vpc-2' }];
      vpcsOutput = vpcs.map(({ vpc_id: name }) => ({ name, value: name }));
      axiosMock.onGet(apiPaths.getVpcsPath, { params: { region } }).reply(200, { vpcs });
    });

    it('return list of vpcs where each item has a name and value', () => {
      expect(awsServices.fetchVpcs({ region })).resolves.toEqual(vpcsOutput);
    });
  });

  describe('when fetchSubnets succeeds', () => {
    let subnets;
    let subnetsOutput;

    beforeEach(() => {
      subnets = [{ subnet_id: 'vpc-1' }, { subnet_id: 'vpc-2' }];
      subnetsOutput = subnets.map(({ subnet_id }) => ({ name: subnet_id, value: subnet_id }));
      axiosMock
        .onGet(apiPaths.getSubnetsPath, { params: { region, vpc_id: vpc } })
        .reply(200, { subnets });
    });

    it('return list of subnets where each item has a name and value', () => {
      expect(awsServices.fetchSubnets({ region, vpc })).resolves.toEqual(subnetsOutput);
    });
  });

  describe('when fetchSecurityGroups succeeds', () => {
    let securityGroups;
    let securityGroupsOutput;

    beforeEach(() => {
      securityGroups = [
        { group_name: 'admin group', group_id: 'group-1' },
        { group_name: 'basic group', group_id: 'group-2' },
      ];
      securityGroupsOutput = securityGroups.map(({ group_id: value, group_name: name }) => ({
        name,
        value,
      }));
      axiosMock
        .onGet(apiPaths.getSecurityGroupsPath, { params: { region, vpc_id: vpc } })
        .reply(200, { security_groups: securityGroups });
    });

    it('return list of security groups where each item has a name and value', () => {
      expect(awsServices.fetchSecurityGroups({ region, vpc })).resolves.toEqual(
        securityGroupsOutput,
      );
    });
  });

  describe('when fetchInstanceTypes succeeds', () => {
    let instanceTypes;
    let instanceTypesOutput;

    beforeEach(() => {
      instanceTypes = [{ instance_type_name: 't2.small' }, { instance_type_name: 't2.medium' }];
      instanceTypesOutput = instanceTypes.map(({ instance_type_name }) => ({
        name: instance_type_name,
        value: instance_type_name,
      }));
      axiosMock.onGet(apiPaths.getInstanceTypesPath).reply(200, { instance_types: instanceTypes });
    });

    it('return list of instance types where each item has a name and value', () => {
      expect(awsServices.fetchInstanceTypes()).resolves.toEqual(instanceTypesOutput);
    });
  });
});
