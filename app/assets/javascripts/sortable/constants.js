/**
 * Default config options for sortablejs.
 * @type {object}
 *
 * @example
 * import Sortable from 'sortablejs';
 *
 * const sortable = Sortable.create(el, {
 *   ...defaultSortableOptions,
 * });
 */
export const defaultSortableOptions = {
  animation: 200,
  forceFallback: true,
  fallbackClass: 'is-dragging',
  fallbackOnBody: true,
  ghostClass: 'is-ghost',
  fallbackTolerance: 1,
};
