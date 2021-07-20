import createFlash from '~/flash';
import axios from '../lib/utils/axios_utils';
import { __ } from '../locale';

export const getSelector = (highlightId) => `.js-feature-highlight[data-highlight=${highlightId}]`;

export function dismiss(endpoint, highlightId) {
  return axios
    .post(endpoint, {
      feature_name: highlightId,
    })
    .catch(() =>
      createFlash({
        message: __(
          'An error occurred while dismissing the feature highlight. Refresh the page and try dismissing again.',
        ),
      }),
    );
}
