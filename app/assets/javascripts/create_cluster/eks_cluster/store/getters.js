export const subnetValid = ({ selectedSubnet }) =>
  Array.isArray(selectedSubnet) && selectedSubnet.length >= 2;
