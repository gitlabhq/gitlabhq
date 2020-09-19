import { repeat } from 'lodash';

const topLevelOrderedRegexp = /^\d{1,3}/;
const nestedLineRegexp = /^\s+/;

/**
 * DISCLAIMER: This is a temporary fix that corrects the indentation
 * spaces of list items. This workaround originates in the usage of
 * the Static Site Editor to edit the Handbook. The Handbook uses a
 * Markdown parser called Kramdown interprets lines indented
 * with two spaces as content within a list. For example:
 *
 * 1. ordered list
 *   - nested unordered list
 *
 * The Static Site Editor uses a different Markdown parser based on the
 * CommonMark specification (official Markdown spec) called ToastMark.
 * When the SSE encounters a nested list with only two spaces, it flattens
 * the list:
 *
 * 1. ordered list
 * - nested unordered list
 *
 * This function attempts to correct this problem before the content is loaded
 * by Toast UI.
 */
const correctNestedContentIndenation = source => {
  const lines = source.split('\n');
  let topLevelOrderedListDetected = false;

  return lines
    .reduce((result, line) => {
      if (topLevelOrderedListDetected && nestedLineRegexp.test(line)) {
        return [...result, line.replace(nestedLineRegexp, repeat(' ', 4))];
      }

      topLevelOrderedListDetected = topLevelOrderedRegexp.test(line);
      return [...result, line];
    }, [])
    .join('\n');
};

const removeOrphanedBrTags = source => {
  /* Until the underlying Squire editor of Toast UI Editor resolves duplicate `<br>` tags, this
    `replace` solution will clear out orphaned `<br>` tags that it generates. Additionally,
    it cleans up orphaned `<br>` tags in the source markdown document that should be new lines.
    https://gitlab.com/gitlab-org/gitlab/-/issues/227602#note_380765330
  */
  return source.replace(/\n^<br>$/gm, '');
};

const format = source => {
  return correctNestedContentIndenation(removeOrphanedBrTags(source));
};

export default format;
