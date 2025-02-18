import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const ROOT_IMAGE_TEXT = s__('HarborRegistry|Root image');
export const NAME_SORT_FIELD = { orderBy: 'NAME', label: __('Name') };

export const ASCENDING_ORDER = 'asc';
export const DESCENDING_ORDER = 'desc';

export const NAME_SORT_FIELD_KEY = 'name';
export const UPDATED_SORT_FIELD_KEY = 'update_time';
export const CREATED_SORT_FIELD_KEY = 'creation_time';

export const SORT_FIELD_MAPPING = {
  NAME: NAME_SORT_FIELD_KEY,
  UPDATED: UPDATED_SORT_FIELD_KEY,
  CREATED: CREATED_SORT_FIELD_KEY,
};

export const DEFAULT_PER_PAGE = 10;

export const HARBOR_REGISTRY_HELP_PAGE_PATH = helpPagePath(
  'user/packages/harbor_container_registry/_index',
);
