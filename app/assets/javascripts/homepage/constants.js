import { __ } from '~/locale';

export const PROJECT_SOURCE_FRECENT = 'FRECENT';
export const PROJECT_SOURCE_STARRED = 'STARRED';
export const PROJECT_SOURCE_PERSONAL = 'PERSONAL';

export const WORK_ITEMS_ICON = 'work-items';
export const WORK_ITEM_ISSUE_ICON = 'work-item-issue';

export const PROJECT_SOURCE_LABELS = {
  [PROJECT_SOURCE_FRECENT]: __('Frequently visited'),
  [PROJECT_SOURCE_PERSONAL]: __('Personal'),
  [PROJECT_SOURCE_STARRED]: __('Starred'),
};

export const DEFAULT_PROJECT_SOURCES = [PROJECT_SOURCE_FRECENT];
