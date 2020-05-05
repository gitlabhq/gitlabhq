import { __, s__, sprintf } from '~/locale';
import { DropdownVariant } from '../constants';

/**
 * Returns string representing current labels
 * selection on dropdown button.
 *
 * @param {object} state
 */
export const dropdownButtonText = (state, getters) => {
  const selectedLabels = getters.isDropdownVariantSidebar
    ? state.labels.filter(label => label.set)
    : state.selectedLabels;

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

/**
 * Returns boolean representing whether dropdown variant
 * is `sidebar`
 * @param {object} state
 */
export const isDropdownVariantSidebar = state => state.variant === DropdownVariant.Sidebar;

/**
 * Returns boolean representing whether dropdown variant
 * is `standalone`
 * @param {object} state
 */
export const isDropdownVariantStandalone = state => state.variant === DropdownVariant.Standalone;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
