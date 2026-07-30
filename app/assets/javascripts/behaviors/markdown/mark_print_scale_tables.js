/**
 * Mark regular tables as print-scale targets.
 *
 * Wide tables are clipped when printing; wikis/utils/print_table_scale.js
 * measures tables with `data-print-scale-target` against their
 * `data-print-scale-container` so the print stylesheet can zoom them to fit.
 *
 * Tables rendered as a component declare the attributes in their own template.
 * (behaviors/components/markdown_table.vue, glql/components/presenters/table.vue).
 * A regular table is its own scrollable element, so it carries both attributes
 * itself.
 *
 * @param {Element[]} tables - Candidate `.md table:not(.code)` elements.
 */
export default function markPrintScaleTables(tables) {
  tables.forEach((table) => {
    // Skip tables inside a wrapper – those are marked in the component template.
    if (table.closest('.gl-table-shadow, [data-sticky-header]')) return;

    // eslint-disable-next-line no-param-reassign
    table.dataset.printScaleContainer = '';
    // eslint-disable-next-line no-param-reassign
    table.dataset.printScaleTarget = '';
  });
}
