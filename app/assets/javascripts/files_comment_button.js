/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, max-len, one-var, one-var-declaration-per-line, quotes, prefer-template, newline-per-chained-call, comma-dangle, new-cap, no-else-return, consistent-return */
/* global notes */

/* Developer beware! Do not add logic to showButton or hideButton
 * that will force a reflow. Doing so will create a signficant performance
 * bottleneck for pages with large diffs. For a comprehensive list of what
 * causes reflows, visit https://gist.github.com/paulirish/5d52fb081b3570c81e3a
 */

const LINE_NUMBER_CLASS = 'diff-line-num';
const LINE_CONTENT_CLASS = 'line_content';
const UNFOLDABLE_LINE_CLASS = 'js-unfold';
const EMPTY_CELL_CLASS = 'empty-cell';
const OLD_LINE_CLASS = 'old_line';
const LINE_COLUMN_CLASSES = `.${LINE_NUMBER_CLASS}, .line_content`;

export default {
  init($diffFile) {
    const userCanCreateNote = $diffFile && $diffFile.parent().data('can-create-note') != null;

    if (userCanCreateNote) {
      $diffFile.on('mouseover', LINE_COLUMN_CLASSES, e => this.showButton(e))
        .on('mouseleave', LINE_COLUMN_CLASSES, e => this.hideButton(e));
    }
  },

  showButton(e) {
    const buttonParentElement = this.getButtonParent(e.currentTarget);

    if (!this.validateButtonParent(buttonParentElement)) return;

    buttonParentElement.classList.add('is-over');
    buttonParentElement.nextElementSibling.classList.add('is-over');
  },

  hideButton(e) {
    const buttonParentElement = this.getButtonParent(e.currentTarget);

    buttonParentElement.classList.remove('is-over');
    buttonParentElement.nextElementSibling.classList.remove('is-over');
  },

  getButtonParent(hoveredElement) {
    if (!notes.isParallelView()) {
      if (hoveredElement.classList.contains(OLD_LINE_CLASS)) {
        return hoveredElement;
      }
      return hoveredElement.parentNode.querySelector(`.${OLD_LINE_CLASS}`);
    } else {
      if (hoveredElement.classList.contains(LINE_NUMBER_CLASS)) {
        return hoveredElement;
      }
      return hoveredElement.previousElementSibling;
    }
  },

  validateButtonParent(buttonParentElement) {
    return !buttonParentElement.classList.contains(EMPTY_CELL_CLASS) && !buttonParentElement.classList.contains(UNFOLDABLE_LINE_CLASS);
  },
};
