import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { FILTER_INHERITORS } from 'ee_else_ce/work_items/board/filter_inheritance/inheritors';

/**
 * Consumes the edition-specific `FILTER_INHERITORS` list (CE + EE-only inheritors) and
 * exposes the two things the board needs. See `./inheritors.js` for how an inheritor maps
 * a board filter to a new-work-item widgets-draft fragment.
 */

/**
 * Widgets-draft keys the inheritors manage. The board resets these before re-seeding so a
 * filter that is no longer active does not linger in the draft shared across board views.
 */
export const INHERITED_WIDGET_TYPES = FILTER_INHERITORS.map((inheritor) => inheritor.widgetType);

/**
 * Merges every inheritor's widgets-draft fragment for the board's active filters.
 * A failing inheritor is logged and skipped so it can't block opening the create modal.
 *
 * @param {import('./inheritors').InheritContext} context
 * @returns {Promise<Object>} Combined widgets-draft fragment (`{}` when nothing is inherited).
 */
export const resolveInheritedWidgetsDraft = async (context) => {
  const fragments = await Promise.all(
    FILTER_INHERITORS.map(async (inheritor) => {
      try {
        return await inheritor.resolve(context);
      } catch (error) {
        Sentry.captureException(error);
        return {};
      }
    }),
  );

  return Object.assign({}, ...fragments);
};
