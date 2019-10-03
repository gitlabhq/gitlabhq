import EC2 from 'aws-sdk/clients/ec2';

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
