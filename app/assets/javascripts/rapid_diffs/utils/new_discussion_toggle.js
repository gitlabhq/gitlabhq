export function moveToggle(toggle, row, side) {
  const previousRow = toggle.closest('tr');
  if (previousRow) delete previousRow.dataset.hasNewDiscussionToggle;
  row.dataset.hasNewDiscussionToggle = ''; // eslint-disable-line no-param-reassign
  const isInline = row.querySelector('[data-position="old"]:first-child + [data-position="new"]');
  const cell = isInline
    ? row.querySelector('[data-position]')
    : row.querySelector(`[data-position="${side}"]`);
  cell.prepend(toggle);
}
