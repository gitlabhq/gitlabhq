import { includes } from 'lodash';
import { parseBoolean } from '~/lib/utils/common_utils';

/**
 * Returns a new dataset that has all the values of keys indicated in
 * booleanAttributes transformed by the parseBoolean() helper function
 *
 * @param {Object}
 * @returns {Object}
 */
export const getParsedDataset = ({ dataset = {}, booleanAttributes = [] } = {}) => {
  const parsedDataset = {};

  Object.keys(dataset).forEach((key) => {
    parsedDataset[key] = includes(booleanAttributes, key)
      ? parseBoolean(dataset[key])
      : dataset[key];
  });

  return parsedDataset;
};
