import { DEFAULT_I18N } from './constants';

function convertToListBoxItems(items) {
  return items.map((item) => ({
    text: item.name,
    value: item.value || item.name,
    protected: item.protected,
    default: item.default,
  }));
}

/**
 * Format multiple lists to array of group options for listbox
 * @param branches list of branches
 * @param tags list of tags
 * @param commits list of commits
 * @param selectedRef the currently selected ref
 * @returns {*[]} array of group items with header and options
 */
export const formatListBoxItems = ({ branches, tags, commits, selectedRef }) => {
  const listBoxItems = [];

  const addToFinalResult = (items, header, shouldFilter = true) => {
    if (!items) return;
    const filteredItems =
      shouldFilter && selectedRef ? items.filter((item) => item.name !== selectedRef.name) : items; // Filter out the selected

    if (!filteredItems?.length) return;
    listBoxItems.push({
      text: header,
      options: convertToListBoxItems(filteredItems).sort(
        // Sort by default first: converts booleans to 1/0 for numeric comparison
        (a, b) => Boolean(b.default) - Boolean(a.default),
      ),
    });
  };

  if (selectedRef) addToFinalResult([selectedRef], DEFAULT_I18N.selected, false);
  addToFinalResult(branches, DEFAULT_I18N.branches);
  addToFinalResult(tags, DEFAULT_I18N.tags);
  addToFinalResult(commits, DEFAULT_I18N.commits);

  return listBoxItems;
};

/**
 * Check error existence and add to final array
 * @param branches list of branches
 * @param tags list of tags
 * @param commits list of commits
 * @returns {*[]} array of error messages
 */
export const formatErrors = (branches, tags, commits) => {
  const errorsList = [];

  if (branches && branches.error) {
    errorsList.push(DEFAULT_I18N.branchesErrorMessage);
  }

  if (tags && tags.error) {
    errorsList.push(DEFAULT_I18N.tagsErrorMessage);
  }

  if (commits && commits.error) {
    errorsList.push(DEFAULT_I18N.commitsErrorMessage);
  }

  return errorsList;
};
