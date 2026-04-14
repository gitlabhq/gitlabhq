/* eslint-disable unicorn/filename-case */
// Filename must be camelCase so it can mock imports
// with syntax `import uniqueId from 'lodash/uniqueId';`

let counter = 0;

const uniqueId = (prefix = '') => {
  counter += 1;
  return `${prefix}${counter}`;
};

uniqueId.reset = () => {
  counter = 0;
};

export default uniqueId;
