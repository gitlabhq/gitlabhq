import { s__ } from '~/locale';

export const DEFAULT_ITEM_LENGTH = 10;
export const MAX_ITEM_LENGTH = 100;

const header = s__('GlobalSearch|Language');

const scopes = {
  BLOBS: 'blobs',
};

const filterParam = 'language';

export const languageFilterData = {
  header,
  scopes,
  filterParam,
};
