/**
 * Returns the label of a GlTable header cell, without the sort icon and the
 * screen reader sort hint that sortable columns add.
 *
 * Reading `th.text()` and keeping the first line depends on the whitespace
 * the template compiler keeps between elements, which differs between the
 * Vue 2 and Vue 3 compilers.
 *
 * @param {Wrapper} th - Test utils wrapper of a `th` element
 * @returns {String}
 */
export const getTableHeaderLabel = (th) => {
  const element = th.element.cloneNode(true);
  element
    .querySelectorAll('.gl-sr-only, [data-testid="sort-icon"]')
    .forEach((node) => node.remove());
  return element.textContent.trim();
};
