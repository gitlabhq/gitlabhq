/**
 * Scale-to-fit helper for wiki print.
 *
 * Wide tables inside scrollable containers are clipped horizontally when
 * printing because browsers honour `overflow: auto/scroll` in print layout
 * (they clip, not paginate, the overflow).  The fix is to shrink each table
 * so its natural width fits within the container's visible width before the
 * browser renders the print layout.  This can lead to Very Small tables --
 * too small to read when *actually* printed -- but (a) truncated tables
 * aren't much better, and (b) a leading use case of print in wikis is in
 * fact print to *PDF* (record-keeping, compliance, etc.).  PDFs are vector
 * and you can zoom into scaled tables as far as you want.
 *
 * CSS `zoom` is used because it scales the element's layout box (unlike
 * `transform: scale`, which only affects the visual layer and leaves the
 * original layout footprint in place).  `zoom` is supported in all evergreen
 * browsers.
 *
 * The scale factor can only be measured on screen, but it must only take
 * effect in print, so we record it as a custom property here and apply the
 * `zoom` from a print rule -- see page_bundles/wiki.scss.
 *
 * Elements opt-in via data attributes created at render time:
 *
 * - `[data-print-scale-target]`    – the <table> that gets zoomed.
 * - `[data-print-scale-container]` – the element whose visible width
 *    constrains the table (the scrollable wrapper; for a regular table,
 *    the table is its own container).
 *
 * Usage:
 *   window.addEventListener('beforeprint', () => {
 *     scaleTablesForPrint(root);
 *     restore = resetScrollForPrint(root);
 *   });
 *   window.addEventListener('afterprint', () => restore());
 */

const SCALE_PROPERTY = '--print-table-scale';

/**
 * Measure how far each table has to shrink to fit within the printed page
 * width, and record it for the print stylesheet to apply.
 *
 * @param {Element} root - The DOM element to search within (e.g. the wiki content area).
 */
export function scaleTablesForPrint(root = document.body) {
  root.querySelectorAll('[data-print-scale-target]').forEach((el) => {
    // For a bare table the target carries the container attribute too, so
    // `closest` resolves to the table itself; wrapped tables resolve to their
    // scrollable wrapper.
    const container = el.closest('[data-print-scale-container]') || el;
    const containerWidth = container.clientWidth;
    const elWidth = el.scrollWidth;

    const ratio = containerWidth / elWidth;

    // Anything the browser can't give us a width for, or that already fits,
    // is printed at its natural size.
    if (containerWidth <= 0 || elWidth <= 0 || ratio >= 1) {
      el.style.removeProperty(SCALE_PROPERTY);
      return;
    }

    el.style.setProperty(SCALE_PROPERTY, String(ratio));
  });
}

/**
 * Scroll every print-scale container back to its origin, and return a function
 * that puts it back where it was.
 *
 * @param {Element} root - The DOM element to search within (e.g. the wiki content area).
 * @returns {Function} A function that restores the saved scroll offsets.
 */
export function resetScrollForPrint(root = document.body) {
  const saved = [];

  for (const container of root.querySelectorAll('[data-print-scale-container]')) {
    saved.push({ container, top: container.scrollTop, left: container.scrollLeft });

    container.scrollTop = 0;
    container.scrollLeft = 0;
  }

  return function restoreScroll() {
    for (const { container, top, left } of saved) {
      container.scrollTop = top;
      container.scrollLeft = left;
    }
  };
}
