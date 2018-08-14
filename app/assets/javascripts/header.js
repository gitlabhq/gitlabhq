import $ from 'jquery';
import { highCountTrim } from '~/lib/utils/text_utility';

/**
 * Updates todo counter when todos are toggled.
 * When count is 0, we hide the badge.
 *
 * @param {jQuery.Event} e
 * @param {String} count
 */
export default function initTodoToggle() {
  $(document).on('todo:toggle', (e, count) => {
    const parsedCount = parseInt(count, 10);
    const $todoPendingCount = $('.todos-count');

    $todoPendingCount.text(highCountTrim(parsedCount));
    $todoPendingCount.toggleClass('hidden', parsedCount === 0);
  });
}
