// Folding a single item would hide its name without making the list any
// shorter, so a tail of one stays as-is.
export const foldTail = (items, max, toOther) =>
  items.length <= max + 1 ? items : [...items.slice(0, max), toOther(items.slice(max))];
