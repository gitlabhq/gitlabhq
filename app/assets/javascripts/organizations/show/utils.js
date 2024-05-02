export const buildDisplayListboxItem = ({ sortName, resourceType, text }) => ({
  text,
  value: `${sortName}_${resourceType}`,
  sortName,
});
