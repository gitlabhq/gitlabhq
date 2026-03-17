import { __, sprintf, createListFormat } from '~/locale';
import {
  PROJECT_SOURCE_FRECENT,
  PROJECT_SOURCE_STARRED,
  PROJECT_SOURCE_PERSONAL,
} from '~/homepage/constants';

const SOURCE_LABELS = {
  [PROJECT_SOURCE_FRECENT]: __('frequently visited'),
  [PROJECT_SOURCE_STARRED]: __('starred'),
  [PROJECT_SOURCE_PERSONAL]: __('personal'),
};

/**
 * Formats a list of project sources into a human-readable message.
 *
 * @param {string[]} selectedSources - Array of project source constants
 * @returns {string} Formatted message like "Displaying frequently visited and starred projects."
 */
export function formatProjectSourcesMessage(selectedSources) {
  const labels = selectedSources.map((source) => SOURCE_LABELS[source]).filter(Boolean);

  if (labels.length === 0) {
    return __('Displaying projects.');
  }

  const formattedList = createListFormat({ type: 'conjunction' }).format(labels);
  return sprintf(__('Displaying %{sources} projects.'), { sources: formattedList });
}
