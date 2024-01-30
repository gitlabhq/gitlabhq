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
 * @returns {*[]} array of group items with header and options
 */
export const formatListBoxItems = (branches, tags, commits) => {
  const listBoxItems = [];

  const addToFinalResult = (items, header) => {
    if (items && items.length > 0) {
      listBoxItems.push({
        text: header,
        options: convertToListBoxItems(items),
      });
    }
  };

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
