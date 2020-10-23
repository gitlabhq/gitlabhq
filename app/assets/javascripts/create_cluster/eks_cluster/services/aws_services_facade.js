import AWS from 'aws-sdk/global';
import EC2 from 'aws-sdk/clients/ec2';
import IAM from 'aws-sdk/clients/iam';

const lookupVpcName = ({ Tags: tags, VpcId: id }) => {
  const nameTag = tags.find(({ Key: key }) => key === 'Name');

  return nameTag ? nameTag.Value : id;
};

export const setAWSConfig = ({ awsCredentials }) => {
  AWS.config = awsCredentials;
};

export const fetchRoles = () => {
  const iam = new IAM();

  return iam
    .listRoles()
    .promise()
    .then(({ Roles: roles }) => roles.map(({ RoleName: name, Arn: value }) => ({ name, value })));
};

export const fetchKeyPairs = ({ region }) => {
  const ec2 = new EC2({ region });

  return ec2
    .describeKeyPairs()
    .promise()
    .then(({ KeyPairs: keyPairs }) => keyPairs.map(({ KeyName: name }) => ({ name, value: name })));
};

export const fetchVpcs = ({ region }) => {
  const ec2 = new EC2({ region });

  return ec2
    .describeVpcs()
    .promise()
    .then(({ Vpcs: vpcs }) =>
      vpcs.map(vpc => ({
        value: vpc.VpcId,
        name: lookupVpcName(vpc),
      })),
    );
};

export const fetchSubnets = ({ vpc, region }) => {
  const ec2 = new EC2({ region });

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
    .then(({ Subnets: subnets }) => subnets.map(({ SubnetId: id }) => ({ value: id, name: id })));
};

export const fetchSecurityGroups = ({ region, vpc }) => {
  const ec2 = new EC2({ region });

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
