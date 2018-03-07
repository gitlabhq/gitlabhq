/* Developer beware! Do not add logic to showButton or hideButton
 * that will force a reflow. Doing so will create a signficant performance
 * bottleneck for pages with large diffs. For a comprehensive list of what
 * causes reflows, visit https://gist.github.com/paulirish/5d52fb081b3570c81e3a
 */

import Cookies from 'js-cookie';

const LINE_NUMBER_CLASS = 'diff-line-num';
const UNFOLDABLE_LINE_CLASS = 'js-unfold';
const NO_COMMENT_CLASS = 'no-comment-btn';
const EMPTY_CELL_CLASS = 'empty-cell';
const OLD_LINE_CLASS = 'old_line';
const LINE_COLUMN_CLASSES = `.${LINE_NUMBER_CLASS}, .line_content`;
const DIFF_CONTAINER_SELECTOR = '.files';
const DIFF_EXPANDED_CLASS = 'diff-expanded';

export default {
  init($diffFile) {
    /* Caching is used only when the following members are *true*.
     * This is because there are likely to be
     * differently configured versions of diffs in the same session.
     * However if these values are true, they
     * will be true in all cases */

    if (!this.userCanCreateNote) {
      // data-can-create-note is an empty string when true, otherwise undefined
      this.userCanCreateNote = $diffFile.closest(DIFF_CONTAINER_SELECTOR).data('canCreateNote') === '';
    }

    this.isParallelView = Cookies.get('diff_view') === 'parallel';

    if (this.userCanCreateNote) {
      $diffFile.on('mouseover', LINE_COLUMN_CLASSES, e => this.showButton(this.isParallelView, e))
        .on('mouseleave', LINE_COLUMN_CLASSES, e => this.hideButton(this.isParallelView, e));
    }
  },

  showButton(isParallelView, e) {
    const buttonParentElement = this.getButtonParent(e.currentTarget, isParallelView);

    if (!this.validateButtonParent(buttonParentElement)) return;

    buttonParentElement.classList.add('is-over');
    buttonParentElement.nextElementSibling.classList.add('is-over');
  },

  hideButton(isParallelView, e) {
    const buttonParentElement = this.getButtonParent(e.currentTarget, isParallelView);

    buttonParentElement.classList.remove('is-over');
    buttonParentElement.nextElementSibling.classList.remove('is-over');
  },

  getButtonParent(hoveredElement, isParallelView) {
    if (isParallelView) {
      if (!hoveredElement.classList.contains(LINE_NUMBER_CLASS)) {
        return hoveredElement.previousElementSibling;
      }
    } else if (!hoveredElement.classList.contains(OLD_LINE_CLASS)) {
      return hoveredElement.parentNode.querySelector(`.${OLD_LINE_CLASS}`);
    }
    return hoveredElement;
  },

  validateButtonParent(buttonParentElement) {
    return !buttonParentElement.classList.contains(EMPTY_CELL_CLASS) &&
      !buttonParentElement.classList.contains(UNFOLDABLE_LINE_CLASS) &&
      !buttonParentElement.classList.contains(NO_COMMENT_CLASS) &&
      !buttonParentElement.parentNode.classList.contains(DIFF_EXPANDED_CLASS);
  },
};
