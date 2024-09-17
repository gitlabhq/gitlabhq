import { pick, has } from 'lodash';

/**
 * @param source
 * @param properties original list of searched collection
 * @returns {{}} reduced source to only include properties
 */
export const pickProperties = (source, properties = []) => {
  if (!source) {
    return {};
  }

  /**
   * If no properties provided
   * search would be executed on provided properties
   */
  if (!properties || properties.length === 0) {
    return source;
  }

  properties.forEach((property) => {
    if (!has(source, property)) {
      throw new Error(`${property} does not exist on object. Please provide valid property list.`);
    }
  });

  return pick(source, properties);
};

/**
 * Search among provided properties on items
 * @param items original list of searched collection
 * @param properties list of properties to search in
 * @param searchQuery search query
 * @returns {*[]}
 */
export const searchInItemsProperties = ({ items = [], properties = [], searchQuery = '' } = {}) => {
  if (!items || items.length === 0) {
    return [];
  }

  if (searchQuery === '') {
    return items;
  }

  const containsValue = (value) =>
    value.toString().toLowerCase().includes(searchQuery.toLowerCase());

  return items.filter((item) => {
    const reducedSource = pickProperties(item, properties);

    return Object.values(reducedSource).some((value) => containsValue(value));
  });
};
