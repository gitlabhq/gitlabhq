import { pickBy } from 'lodash';
import { truncateNamespace } from '~/lib/utils/text_utility';
import {
  GROUPS_CATEGORY,
  PROJECTS_CATEGORY,
  MERGE_REQUEST_CATEGORY,
  ISSUES_CATEGORY,
  RECENT_EPICS_CATEGORY,
} from '~/vue_shared/global_search/constants';
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
  const { id, category, value, label, url: href, avatar_url } = item;
  let namespace;
  const text = value || label;
  if (value) {
    namespace = getTruncatedNamespace(label);
  }
  const avatarSize = getAvatarSize(category);
  const entityId = getEntityId(item, searchContext);
  const entityName = getEntityName(item, searchContext);

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
    },
    (val) => val !== undefined,
  );
};
