export const queryTypes = {
  business: 'business',
  response: 'response',
  system: 'system',
};

export const formDataValidator = val => {
  const fieldNames = Object.keys(val);
  const requiredFields = ['title', 'query', 'yLabel', 'unit', 'group', 'legend'];

  return requiredFields.every(name => fieldNames.includes(name));
};
