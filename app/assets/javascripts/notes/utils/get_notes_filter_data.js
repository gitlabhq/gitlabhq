/**
 * Returns parsed notes filter data from a given element's dataset
 *
 * @param {Element} el containing info in the dataset
 */
export const getNotesFilterData = (el) => {
  const { notesFilterValue: valueData, notesFilters: filtersData } = el.dataset;

  const filtersParsed = filtersData ? JSON.parse(filtersData) : {};
  const filters = Object.keys(filtersParsed).map((key) => ({
    title: key,
    value: filtersParsed[key],
  }));

  const value = valueData ? Number(valueData) : undefined;

  return {
    notesFilters: filters,
    notesFilterValue: value,
  };
};
