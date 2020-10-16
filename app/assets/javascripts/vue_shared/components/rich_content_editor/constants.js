import { __ } from '~/locale';

export const CUSTOM_EVENTS = {
  openAddImageModal: 'gl_openAddImageModal',
  openInsertVideoModal: 'gl_openInsertVideoModal',
};

export const YOUTUBE_URL = 'https://www.youtube.com';

export const YOUTUBE_EMBED_URL = `${YOUTUBE_URL}/embed`;

export const ALLOWED_VIDEO_ORIGINS = [YOUTUBE_URL];

/* eslint-disable @gitlab/require-i18n-strings */
export const TOOLBAR_ITEM_CONFIGS = [
  { icon: 'heading', event: 'openHeadingSelect', classes: 'tui-heading', tooltip: __('Headings') },
  { icon: 'bold', command: 'Bold', tooltip: __('Add bold text') },
  { icon: 'italic', command: 'Italic', tooltip: __('Add italic text') },
  { icon: 'strikethrough', command: 'Strike', tooltip: __('Add strikethrough text') },
  { isDivider: true },
  { icon: 'quote', command: 'Blockquote', tooltip: __('Insert a quote') },
  { icon: 'link', event: 'openPopupAddLink', tooltip: __('Add a link') },
  { isDivider: true },
  { icon: 'list-bulleted', command: 'UL', tooltip: __('Add a bullet list') },
  { icon: 'list-numbered', command: 'OL', tooltip: __('Add a numbered list') },
  { icon: 'list-task', command: 'Task', tooltip: __('Add a task list') },
  { icon: 'list-indent', command: 'Indent', tooltip: __('Indent') },
  { icon: 'list-outdent', command: 'Outdent', tooltip: __('Outdent') },
  { isDivider: true },
  { icon: 'dash', command: 'HR', tooltip: __('Add a line') },
  { icon: 'table', event: 'openPopupAddTable', classes: 'tui-table', tooltip: __('Add a table') },
  { icon: 'doc-image', event: CUSTOM_EVENTS.openAddImageModal, tooltip: __('Insert an image') },
  { icon: 'live-preview', event: CUSTOM_EVENTS.openInsertVideoModal, tooltip: __('Insert video') },
  { isDivider: true },
  { icon: 'code', command: 'Code', tooltip: __('Insert inline code') },
  { icon: 'doc-code', command: 'CodeBlock', tooltip: __('Insert a code block') },
];

export const EDITOR_TYPES = {
  markdown: 'markdown',
  wysiwyg: 'wysiwyg',
};

export const EDITOR_HEIGHT = '100%';

export const EDITOR_PREVIEW_STYLE = 'horizontal';

export const IMAGE_TABS = { UPLOAD_TAB: 0, URL_TAB: 1 };

export const MAX_FILE_SIZE = 2097152; // 2Mb

export const VIDEO_ATTRIBUTES = {
  width: '560',
  height: '315',
  frameBorder: '0',
  allow: 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture',
};
