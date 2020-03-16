import { __, s__, sprintf } from '~/locale';

/**
 * Returns string representing current labels
 * selection on dropdown button.
 *
 * @param {object} state
 */
export const dropdownButtonText = state => {
  const selectedLabels = state.labels.filter(label => label.set);
  if (!selectedLabels.length) {
    return __('Label');
  } else if (selectedLabels.length > 1) {
    return sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
      firstLabelName: selectedLabels[0].title,
      remainingLabelCount: selectedLabels.length - 1,
    });
  }
  return selectedLabels[0].title;
};

/**
 * Returns array containing only label IDs from
 * selectedLabels array.
 * @param {object} state
 */
export const selectedLabelsList = state => state.selectedLabels.map(label => label.id);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
