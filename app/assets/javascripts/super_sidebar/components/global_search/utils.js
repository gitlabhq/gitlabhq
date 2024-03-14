import { pickBy } from 'lodash';
import { slugify, truncateNamespace } from '~/lib/utils/text_utility';
import {
  GROUPS_CATEGORY,
  PROJECTS_CATEGORY,
  MERGE_REQUEST_CATEGORY,
  ISSUES_CATEGORY,
  RECENT_EPICS_CATEGORY,
  COMMAND_PALETTE_TYPE_PAGES,
  COMMAND_PALETTE_TYPE_FILES,
} from '~/vue_shared/global_search/constants';

import {
  TRACKING_CLICK_COMMAND_PALETTE_ITEM,
  COMMON_HANDLES,
  USERS_GROUP_TITLE,
  PROJECTS_GROUP_TITLE,
} from './command_palette/constants';

import { LARGE_AVATAR_PX, SMALL_AVATAR_PX } from './constants';

const getTruncatedNamespace = (string) => {
  if (string.split(' / ').length > 2) {
    return truncateNamespace(string);
  }

  return string;
};
const getAvatarSize = (category) => {
  if (category === GROUPS_CATEGORY || category === PROJECTS_CATEGORY) {
    return LARGE_AVATAR_PX;
  }

  return SMALL_AVATAR_PX;
};

const getEntityId = (item, searchContext) => {
  switch (item.category) {
    case GROUPS_CATEGORY:
    case RECENT_EPICS_CATEGORY:
      return item.group_id || item.id || searchContext?.group?.id;
    case PROJECTS_CATEGORY:
    case ISSUES_CATEGORY:
    case MERGE_REQUEST_CATEGORY:
      return item.project_id || item.id || searchContext?.project?.id;
    default:
      return item.id;
  }
};
const getEntityName = (item, searchContext) => {
  switch (item.category) {
    case GROUPS_CATEGORY:
    case RECENT_EPICS_CATEGORY:
      return item.group_name || item.value || item.label || searchContext?.group?.name;
    case PROJECTS_CATEGORY:
    case ISSUES_CATEGORY:
    case MERGE_REQUEST_CATEGORY:
      return item.project_name || item.value || item.label || searchContext?.project?.name;
    default:
      return item.label;
  }
};

export const getFormattedItem = (item, searchContext) => {
  const { id, category, value, label, url: href, avatar_url, name } = item;
  let namespace;
  const text = value || label || name;
  if (value) {
    namespace = getTruncatedNamespace(label);
  }
  const avatarSize = getAvatarSize(category);
  const entityId = getEntityId(item, searchContext);
  const entityName = getEntityName(item, searchContext);
  const trackingLabel = slugify(category ?? '');
  const trackingAttrs = trackingLabel
    ? {
        extraAttrs: {
          'data-track-action': TRACKING_CLICK_COMMAND_PALETTE_ITEM,
          'data-track-label': slugify(category, '_'),
        },
      }
    : {};

  return pickBy(
    {
      id,
      category,
      value,
      label,
      text,
      href,
      avatar_url,
      avatar_size: avatarSize,
      namespace,
      entity_id: entityId,
      entity_name: entityName,
      ...trackingAttrs,
    },
    (val) => val !== undefined,
  );
};

export const commandPaletteDropdownItems = [
  {
    value: COMMON_HANDLES[0],
    text: COMMAND_PALETTE_TYPE_PAGES,
  },
  {
    value: COMMON_HANDLES[1],
    text: USERS_GROUP_TITLE,
  },
  {
    value: COMMON_HANDLES[2],
    text: PROJECTS_GROUP_TITLE,
  },
  {
    value: COMMON_HANDLES[3],
    text: COMMAND_PALETTE_TYPE_FILES,
  },
];
