import EC2 from 'aws-sdk/clients/ec2';
import IAM from 'aws-sdk/clients/iam';

export const fetchRoles = () => {
  const iam = new IAM();

  return iam
    .listRoles()
    .promise()
    .then(({ Roles: roles }) => roles.map(({ RoleName: name }) => ({ name })));
};

export const fetchKeyPairs = () => {
  const ec2 = new EC2();

  return ec2
    .describeKeyPairs()
    .promise()
    .then(({ KeyPairs: keyPairs }) => keyPairs.map(({ RegionName: name }) => ({ name })));
};

export const fetchRegions = () => {
  const ec2 = new EC2();

  return ec2
    .describeRegions()
    .promise()
    .then(({ Regions: regions }) =>
      regions.map(({ RegionName: name }) => ({
        name,
        value: name,
      })),
    );
};

export const fetchVpcs = () => {
  const ec2 = new EC2();

  return ec2
    .describeVpcs()
    .promise()
    .then(({ Vpcs: vpcs }) =>
      vpcs.map(({ VpcId: id }) => ({
        value: id,
        name: id,
      })),
    );
};

export const fetchSubnets = ({ vpc }) => {
  const ec2 = new EC2();

  return ec2
    .describeSubnets({
      Filters: [
        {
          Name: 'vpc-id',
          Values: [vpc],
        },
      ],
    })
    .promise()
    .then(({ Subnets: subnets }) => subnets.map(({ SubnetId: id }) => ({ id, name: id })));
};

export const fetchSecurityGroups = ({ vpc }) => {
  const ec2 = new EC2();

  return ec2
    .describeSecurityGroups({
      Filters: [
        {
          Name: 'vpc-id',
          Values: [vpc],
        },
      ],
    })
    .promise()
    .then(({ SecurityGroups: securityGroups }) =>
      securityGroups.map(({ GroupName: name, GroupId: value }) => ({ name, value })),
    );
};

export default () => {};
