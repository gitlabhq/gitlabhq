import AWS from 'aws-sdk/global';
import EC2 from 'aws-sdk/clients/ec2';
import {
  setAWSConfig,
  fetchRoles,
  fetchRegions,
  fetchKeyPairs,
  fetchVpcs,
  fetchSubnets,
  fetchSecurityGroups,
  DEFAULT_REGION,
} from '~/create_cluster/eks_cluster/services/aws_services_facade';

const mockListRolesPromise = jest.fn();
const mockDescribeRegionsPromise = jest.fn();
const mockDescribeKeyPairsPromise = jest.fn();
const mockDescribeVpcsPromise = jest.fn();
const mockDescribeSubnetsPromise = jest.fn();
const mockDescribeSecurityGroupsPromise = jest.fn();

jest.mock('aws-sdk/clients/iam', () =>
  jest.fn().mockImplementation(() => ({
    listRoles: jest.fn().mockReturnValue({ promise: mockListRolesPromise }),
  })),
);

jest.mock('aws-sdk/clients/ec2', () =>
  jest.fn().mockImplementation(() => ({
    describeRegions: jest.fn().mockReturnValue({ promise: mockDescribeRegionsPromise }),
    describeKeyPairs: jest.fn().mockReturnValue({ promise: mockDescribeKeyPairsPromise }),
    describeVpcs: jest.fn().mockReturnValue({ promise: mockDescribeVpcsPromise }),
    describeSubnets: jest.fn().mockReturnValue({ promise: mockDescribeSubnetsPromise }),
    describeSecurityGroups: jest
      .fn()
      .mockReturnValue({ promise: mockDescribeSecurityGroupsPromise }),
  })),
);

describe('awsServicesFacade', () => {
  let region;
  let vpc;

  beforeEach(() => {
    region = 'west-1';
    vpc = 'vpc-2';
  });

  it('setAWSConfig configures AWS SDK with provided credentials and default region', () => {
    const awsCredentials = {
      accessKeyId: 'access-key',
      secretAccessKey: 'secret-key',
      sessionToken: 'session-token',
    };

    setAWSConfig({ awsCredentials });

    expect(AWS.config).toEqual({
      ...awsCredentials,
      region: DEFAULT_REGION,
    });
  });

  describe('when fetchRoles succeeds', () => {
    let roles;
    let rolesOutput;

    beforeEach(() => {
      roles = [
        { RoleName: 'admin', Arn: 'aws::admin' },
        { RoleName: 'read-only', Arn: 'aws::read-only' },
      ];
      rolesOutput = roles.map(({ RoleName: name, Arn: value }) => ({ name, value }));

      mockListRolesPromise.mockResolvedValueOnce({ Roles: roles });
    });

    it('return list of regions where each item has a name and value', () => {
      expect(fetchRoles()).resolves.toEqual(rolesOutput);
    });
  });

  describe('when fetchRegions succeeds', () => {
    let regions;
    let regionsOutput;

    beforeEach(() => {
      regions = [{ RegionName: 'east-1' }, { RegionName: 'west-2' }];
      regionsOutput = regions.map(({ RegionName: name }) => ({ name, value: name }));

      mockDescribeRegionsPromise.mockResolvedValueOnce({ Regions: regions });
    });

    it('return list of roles where each item has a name and value', () => {
      expect(fetchRegions()).resolves.toEqual(regionsOutput);
    });
  });

  describe('when fetchKeyPairs succeeds', () => {
    let keyPairs;
    let keyPairsOutput;

    beforeEach(() => {
      keyPairs = [{ KeyName: 'key-pair' }, { KeyName: 'key-pair-2' }];
      keyPairsOutput = keyPairs.map(({ KeyName: name }) => ({ name, value: name }));

      mockDescribeKeyPairsPromise.mockResolvedValueOnce({ KeyPairs: keyPairs });
    });

    it('instantatiates ec2 service with provided region', () => {
      fetchKeyPairs({ region });
      expect(EC2).toHaveBeenCalledWith({ region });
    });

    it('return list of key pairs where each item has a name and value', () => {
      expect(fetchKeyPairs({ region })).resolves.toEqual(keyPairsOutput);
    });
  });

  describe('when fetchVpcs succeeds', () => {
    let vpcs;
    let vpcsOutput;

    beforeEach(() => {
      vpcs = [{ VpcId: 'vpc-1', Tags: [] }, { VpcId: 'vpc-2', Tags: [] }];
      vpcsOutput = vpcs.map(({ VpcId: vpcId }) => ({ name: vpcId, value: vpcId }));

      mockDescribeVpcsPromise.mockResolvedValueOnce({ Vpcs: vpcs });
    });

    it('instantatiates ec2 service with provided region', () => {
      fetchVpcs({ region });
      expect(EC2).toHaveBeenCalledWith({ region });
    });

    it('return list of vpcs where each item has a name and value', () => {
      expect(fetchVpcs({ region })).resolves.toEqual(vpcsOutput);
    });
  });

  describe('when vpcs has a Name tag', () => {
    const vpcName = 'vpc name';
    const vpcId = 'vpc id';
    let vpcs;
    let vpcsOutput;

    beforeEach(() => {
      vpcs = [{ VpcId: vpcId, Tags: [{ Key: 'Name', Value: vpcName }] }];
      vpcsOutput = [{ name: vpcName, value: vpcId }];

      mockDescribeVpcsPromise.mockResolvedValueOnce({ Vpcs: vpcs });
    });

    it('uses name tag value as the vpc name', () => {
      expect(fetchVpcs({ region })).resolves.toEqual(vpcsOutput);
    });
  });

  describe('when fetchSubnets succeeds', () => {
    let subnets;
    let subnetsOutput;

    beforeEach(() => {
      subnets = [{ SubnetId: 'subnet-1' }, { SubnetId: 'subnet-2' }];
      subnetsOutput = subnets.map(({ SubnetId }) => ({ name: SubnetId, value: SubnetId }));

      mockDescribeSubnetsPromise.mockResolvedValueOnce({ Subnets: subnets });
    });

    it('return list of subnets where each item has a name and value', () => {
      expect(fetchSubnets({ region, vpc })).resolves.toEqual(subnetsOutput);
    });
  });

  describe('when fetchSecurityGroups succeeds', () => {
    let securityGroups;
    let securityGroupsOutput;

    beforeEach(() => {
      securityGroups = [
        { GroupName: 'admin group', GroupId: 'group-1' },
        { GroupName: 'basic group', GroupId: 'group-2' },
      ];
      securityGroupsOutput = securityGroups.map(({ GroupId: value, GroupName: name }) => ({
        name,
        value,
      }));

      mockDescribeSecurityGroupsPromise.mockResolvedValueOnce({ SecurityGroups: securityGroups });
    });

    it('return list of security groups where each item has a name and value', () => {
      expect(fetchSecurityGroups({ region, vpc })).resolves.toEqual(securityGroupsOutput);
    });
  });
});
