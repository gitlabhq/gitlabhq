import { sprintf, s__ } from '~/locale';

/**
 * Combines each given item into a noun series sentence fragment. It does this
 * in a way that supports i18n by giving context and punctuation to the locale
 * functions.
 *
 * **Examples:**
 *
 * - `["A", "B"] => "A and B"`
 * - `["A", "B", "C"] => "A, B, and C"`
 *
 * **Why only nouns?**
 *
 * Some languages need a bit more context to translate other series.
 *
 * @param {String[]} items
 */
export const toNounSeriesText = items => {
  if (items.length === 0) {
    return '';
  } else if (items.length === 1) {
    return items[0];
  } else if (items.length === 2) {
    return sprintf(s__('nounSeries|%{firstItem} and %{lastItem}'), {
      firstItem: items[0],
      lastItem: items[1],
    });
  }

  return items.reduce((item, nextItem, idx) =>
    idx === items.length - 1
      ? sprintf(s__('nounSeries|%{item}, and %{lastItem}'), { item, lastItem: nextItem })
      : sprintf(s__('nounSeries|%{item}, %{nextItem}'), { item, nextItem }),
  );
};

export default {
  toNounSeriesText,
};
