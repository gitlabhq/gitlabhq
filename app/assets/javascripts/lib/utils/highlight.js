import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { sanitize } from '~/lib/dompurify';

/**
 * Wraps substring matches with HTML `<span>` elements.
 * Inputs are sanitized before highlighting, so this
 * filter is safe to use with `v-html` (as long as `matchPrefix`
 * and `matchSuffix` are not being dynamically generated).
 *
 * Note that this function can't be used inside `v-html` as a filter
 * (Vue filters cannot be used inside `v-html`).
 *
 * @param {String} string The string to highlight
 * @param {String} match The substring match to highlight in the string
 * @param {String} matchPrefix The string to insert at the beginning of a match
 * @param {String} matchSuffix The string to insert at the end of a match
 */
// eslint-disable-next-line max-params
export default function highlight(string, match = '', matchPrefix = '<b>', matchSuffix = '</b>') {
  if (!string) {
    return '';
  }

  if (!match) {
    return sanitize(string.toString(), { ALLOWED_TAGS: [] });
  }

  const sanitizedValue = sanitize(string.toString(), { ALLOWED_TAGS: [] });

  // occurrences is an array of character indices that should be
  // highlighted in the original string, i.e. [3, 4, 5, 7]
  const occurrences = fuzzaldrinPlus.match(sanitizedValue, match.toString());

  return sanitizedValue
    .split('')
    .map((character, i) => {
      if (occurrences.includes(i)) {
        return `${matchPrefix}${character}${matchSuffix}`;
      }

      return character;
    })
    .join('');
}
