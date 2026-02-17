import { __ } from '~/locale';

export const PROJECT_SOURCE_FRECENT = 'FRECENT';
export const PROJECT_SOURCE_STARRED = 'STARRED';

export const PROJECT_SOURCE_LABELS = {
  [PROJECT_SOURCE_FRECENT]: __('Frequently visited'),
  [PROJECT_SOURCE_STARRED]: __('Starred'),
};

export const DEFAULT_PROJECT_SOURCES = [PROJECT_SOURCE_FRECENT];
