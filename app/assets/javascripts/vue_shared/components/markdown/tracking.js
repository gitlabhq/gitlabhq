import Tracking from '~/tracking';

export const EDITOR_TRACKING_LABEL = 'editor_tracking';
export const EDITOR_TYPE_ACTION = 'editor_type_used';
export const EDITOR_TYPE_PLAIN_TEXT_EDITOR = 'editor_type_plain_text_editor';
export const EDITOR_TYPE_RICH_TEXT_EDITOR = 'editor_type_rich_text_editor';

export const trackSavedUsingEditor = (isRichText, context) => {
  Tracking.event(undefined, EDITOR_TYPE_ACTION, {
    label: EDITOR_TRACKING_LABEL,
    editorType: isRichText ? EDITOR_TYPE_RICH_TEXT_EDITOR : EDITOR_TYPE_PLAIN_TEXT_EDITOR,
    context,
  });
};
