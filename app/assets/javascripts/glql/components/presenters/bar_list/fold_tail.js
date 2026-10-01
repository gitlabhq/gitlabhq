import { s__, sprintf } from '~/locale';

// Folding a single item would hide its name without making the list any
// shorter, so a tail of one stays as-is.
export const foldTail = (items, max, toOther) =>
  items.length <= max + 1 ? items : [...items.slice(0, max), toOther(items.slice(max))];

const numbersIn = (values) => values.filter((value) => typeof value === 'number');
const sumOf = (values) => numbersIn(values).reduce((total, value) => total + value, 0);

// Ranks stacked series by total and folds the tail into one Other series. A group where no
// folded series has a number gets `missingValue`, so a chart can leave that segment out.
export const foldSeries = ({ bars, groups, max, missingValue = 0 }) => {
  const ranked = [...bars].sort((a, b) => sumOf(b.data) - sumOf(a.data));

  return foldTail(ranked, max, (folded) => ({
    name: sprintf(s__('Glql|Other (%{count})'), { count: folded.length }),
    data: groups.map((_, index) => {
      const values = numbersIn(folded.map((bar) => bar.data[index]));
      return values.length ? sumOf(values) : missingValue;
    }),
  }));
};

// The same rule for rows: a single row past the limit rides along on the
// first page rather than earning a page of its own.
export const pageSizeFor = (total, max) => (total === max + 1 ? total : max);

export const pageOf = (items, page, size) => items.slice(page * size, (page + 1) * size);
