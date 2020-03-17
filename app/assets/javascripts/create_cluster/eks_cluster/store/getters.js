// eslint-disable-next-line import/prefer-default-export
export const subnetValid = ({ selectedSubnet }) =>
  Array.isArray(selectedSubnet) && selectedSubnet.length >= 2;
