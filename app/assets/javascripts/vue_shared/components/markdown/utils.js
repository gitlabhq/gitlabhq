import {
  EDITING_MODE_KEY,
  EDITING_MODE_MARKDOWN_FIELD,
  EDITING_MODE_CONTENT_EDITOR,
} from '../../constants';

/**
 * Resolves the editing mode MarkdownEditor will start in.
 *
 * @returns {string} EDITING_MODE_CONTENT_EDITOR or EDITING_MODE_MARKDOWN_FIELD
 */
export function getInitialEditingMode() {
  switch (window.gon?.text_editor) {
    case 'rich_text_editor':
      return EDITING_MODE_CONTENT_EDITOR;
    case 'plain_text_editor':
      return EDITING_MODE_MARKDOWN_FIELD;
    default:
      return localStorage.getItem(EDITING_MODE_KEY) || EDITING_MODE_MARKDOWN_FIELD;
  }
}
