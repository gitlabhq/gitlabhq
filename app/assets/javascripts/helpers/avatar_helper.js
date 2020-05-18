import { escape } from 'lodash';
import { getFirstCharacterCapitalized } from '~/lib/utils/text_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export const DEFAULT_SIZE_CLASS = 's40';
export const IDENTICON_BG_COUNT = 7;

export function getIdenticonBackgroundClass(entityId) {
  // If a GraphQL string id is passed in, convert it to the entity number
  const id = typeof entityId === 'string' ? getIdFromGraphQLId(entityId) : entityId;
  const type = (id % IDENTICON_BG_COUNT) + 1;
  return `bg${type}`;
}

export function getIdenticonTitle(entityName) {
  return getFirstCharacterCapitalized(entityName) || ' ';
}

export function renderIdenticon(entity, options = {}) {
  const { sizeClass = DEFAULT_SIZE_CLASS } = options;

  const bgClass = getIdenticonBackgroundClass(entity.id);
  const title = getIdenticonTitle(entity.name);

  return `<div class="avatar identicon ${escape(sizeClass)} ${escape(bgClass)}">${escape(
    title,
  )}</div>`;
}

export function renderAvatar(entity, options = {}) {
  if (!entity.avatar_url) {
    return renderIdenticon(entity, options);
  }

  const { sizeClass = DEFAULT_SIZE_CLASS } = options;

  return `<img src="${escape(entity.avatar_url)}" class="avatar ${escape(sizeClass)}" />`;
}
