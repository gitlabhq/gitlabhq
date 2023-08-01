import Tracking from '~/tracking';

export const MARKDOWN_EDITOR_TRACKING_LABEL = 'markdown_editor';
export const RICH_TEXT_EDITOR_TRACKING_LABEL = 'rich_text_editor';

export const SAVE_MARKDOWN_TRACKING_ACTION = 'save_markdown';
export const TOOLBAR_CONTROL_TRACKING_ACTION = 'execute_toolbar_control';

export const trackSavedUsingEditor = (isRichText, property) => {
  Tracking.event(undefined, SAVE_MARKDOWN_TRACKING_ACTION, {
    label: isRichText ? RICH_TEXT_EDITOR_TRACKING_LABEL : MARKDOWN_EDITOR_TRACKING_LABEL,
    property,
  });
};
