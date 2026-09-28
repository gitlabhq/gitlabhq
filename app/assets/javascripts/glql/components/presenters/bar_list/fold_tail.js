// Folding a single item would hide its name without making the list any
// shorter, so a tail of one stays as-is.
export const foldTail = (items, max, toOther) =>
  items.length <= max + 1 ? items : [...items.slice(0, max), toOther(items.slice(max))];

// The same rule for rows: a single row past the limit rides along on the
// first page rather than earning a page of its own.
export const pageSizeFor = (total, max) => (total === max + 1 ? total : max);

export const pageOf = (items, page, size) => items.slice(page * size, (page + 1) * size);
