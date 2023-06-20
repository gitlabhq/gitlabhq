import { n__ } from '~/locale';

/**
 * Accepts an array of options and an array of selected option IDs
 * and optionally a placeholder and maximum number of options to show.
 *
 * Returns a string with the text of the selected options:
 * - If no options are selected, returns the placeholder or an empty string.
 * - If less than maxOptionsShown is selected, returns the text of those options comma-separated.
 * - If more than maxOptionsShown is selected, returns the text of those options comma-separated
 *   followed by the text "+X more", where X is the number of additional selected options
 *
 * @param {Object} opts
 * @param {Array<{ id: number | string, value: string }>} opts.options
 * @param {Array<{ id: number | string }>} opts.selected
 * @param {String} opts.placeholder - Placeholder when no option is selected
 * @param {Integer} opts.maxOptionsShown – Max number of options to show
 * @returns {String}
 */
export const getSelectedOptionsText = ({
  options,
  selected,
  placeholder = '',
  maxOptionsShown = 1,
}) => {
  const selectedOptions = options.filter(({ id, value }) => selected.includes(id || value));

  if (selectedOptions.length === 0) {
    return placeholder;
  }

  const optionTexts = selectedOptions.map((option) => option.text);

  if (selectedOptions.length <= maxOptionsShown) {
    return optionTexts.join(', ');
  }

  // Prevent showing "+-1 more" when the array is empty.
  const additionalItemsCount = selectedOptions.length - maxOptionsShown;
  return `${optionTexts.slice(0, maxOptionsShown).join(', ')} ${n__(
    '+%d more',
    '+%d more',
    additionalItemsCount,
  )}`;
};
