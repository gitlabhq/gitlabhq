/**
 * Return a shallow copy of an array with two items swapped.
 *
 * @param {Array} array - The source array
 * @param {Number} leftIndex - Index of the first item
 * @param {Number} rightIndex - Index of the second item
 * @returns {Array} new array with the left and right items swapped
 */
export const swapArrayItems = (array, leftIndex = 0, rightIndex = 0) => {
  const copy = array.slice();

  if (leftIndex >= array.length || leftIndex < 0 || rightIndex >= array.length || rightIndex < 0) {
    return copy;
  }

  const temp = copy[leftIndex];
  copy[leftIndex] = copy[rightIndex];
  copy[rightIndex] = temp;
  return copy;
};

/**
 * Return an array with all duplicate items from the given array
 *
 * @param {Array} array - The source array
 * @returns {Array} new array with all duplicate items
 */
export const getDuplicateItemsFromArray = (array) => [
  ...new Set(array.filter((value, index) => array.indexOf(value) !== index)),
];
