import { __, s__, sprintf } from '~/locale';
import {
  VARIANT_EMBEDDED,
  VARIANT_SIDEBAR,
  VARIANT_STANDALONE,
} from '~/sidebar/components/labels/labels_select_widget/constants';

/**
 * Returns string representing current labels
 * selection on dropdown button.
 *
 * @param {object} state
 */
export const dropdownButtonText = (state, getters) => {
  const selectedLabels =
    getters.isDropdownVariantSidebar || getters.isDropdownVariantEmbedded
      ? state.labels.filter((label) => label.set || label.indeterminate)
      : state.selectedLabels;

  if (!selectedLabels.length) {
    return state.dropdownButtonText || __('Label');
  }
  if (selectedLabels.length > 1) {
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
export const selectedLabelsList = (state) => state.selectedLabels.map((label) => label.id);

/**
 * Returns boolean representing whether dropdown variant
 * is `sidebar`
 * @param {object} state
 */
export const isDropdownVariantSidebar = (state) => state.variant === VARIANT_SIDEBAR;

/**
 * Returns boolean representing whether dropdown variant
 * is `standalone`
 * @param {object} state
 */
export const isDropdownVariantStandalone = (state) => state.variant === VARIANT_STANDALONE;

/**
 * Returns boolean representing whether dropdown variant
 * is `embedded`
 * @param {object} state
 */
export const isDropdownVariantEmbedded = (state) => state.variant === VARIANT_EMBEDDED;
