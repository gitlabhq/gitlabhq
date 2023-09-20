export const buildDisplayListboxItem = ({ filter, resourceType, text }) => ({
  text,
  value: `${filter}_${resourceType}`,
});
