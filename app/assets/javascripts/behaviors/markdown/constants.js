export const GFM_POPOVER_SELECTOR =
  '.gfm-issue, .gfm-work_item, .gfm-merge_request, .gfm-epic, .gfm-milestone, .gfm-commit';

export const GFM_LIGHTBOX_IMAGE_SELECTOR = 'a>img';

export const MARKDOWN_TABLE_EXPANDED_KEY = 'markdown_table_expanded';
export const MARKDOWN_TABLE_EXPANDED_EVENT = 'gl-markdown-table-expanded';

export const unrestrictedPages = [
  // Group wiki
  'groups:wikis:show',
  'groups:wikis:edit',
  'groups:wikis:create',

  // Project wiki
  'projects:wikis:show',
  'projects:wikis:edit',
  'projects:wikis:create',

  // Project files
  'projects:show',
  'projects:blob:show',
];
