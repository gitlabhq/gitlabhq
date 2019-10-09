import EC2 from 'aws-sdk/clients/ec2';
import IAM from 'aws-sdk/clients/iam';

export const fetchRoles = () =>
  new Promise((resolve, reject) => {
    const iam = new IAM();

    iam
      .listRoles()
      .on('success', ({ data: { Roles: roles } }) => {
        const transformedRoles = roles.map(({ RoleName: name }) => ({ name }));

        resolve(transformedRoles);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export const fetchKeyPairs = () =>
  new Promise((resolve, reject) => {
    const ec2 = new EC2();

    ec2
      .describeKeyPairs()
      .on('success', ({ data: { KeyPairs: keyPairs } }) => {
        const transformedKeyPairs = keyPairs.map(({ RegionName: name }) => ({ name }));

        resolve(transformedKeyPairs);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export const fetchRegions = () =>
  new Promise((resolve, reject) => {
    const ec2 = new EC2();

    ec2
      .describeRegions()
      .on('success', ({ data: { Regions: regions } }) => {
        const transformedRegions = regions.map(({ RegionName: name }) => ({ name }));

        resolve(transformedRegions);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export const fetchVpcs = () =>
  new Promise((resolve, reject) => {
    const ec2 = new EC2();

    ec2
      .describeVpcs()
      .on('success', ({ data: { Vpcs: vpcs } }) => {
        const transformedVpcs = vpcs.map(({ VpcId: id }) => ({ id, name: id }));

        resolve(transformedVpcs);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export const fetchSubnets = ({ vpc }) =>
  new Promise((resolve, reject) => {
    const ec2 = new EC2();

    ec2
      .describeSubnets({
        Filters: [
          {
            Name: 'vpc-id',
            Values: [vpc.id],
          },
        ],
      })
      .on('success', ({ data: { Subnets: subnets } }) => {
        const transformedSubnets = subnets.map(({ SubnetId: id }) => ({ id, name: id }));

        resolve(transformedSubnets);
      })
      .on('error', error => {
        reject(error);
      })
      .send();
  });

export default () => {};
