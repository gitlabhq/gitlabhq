import { isNil, omitBy } from 'lodash';
import { objectToQuery, joinPaths, encodeSaferUrl } from '~/lib/utils/url_utility';
import { TRACKING_UNKNOWN_ID } from '~/super_sidebar/constants';
import {
  SEARCH_SCOPE,
  GLOBAL_COMMANDS_GROUP_TITLE,
  TRACKING_CLICK_COMMAND_PALETTE_ITEM,
} from './constants';

export const commandMapper = ({ name, items }) => {
  // TODO: we filter out invite_members for now, because it is complicated to add the invite members modal here
  // and is out of scope for the basic command palette items. If it proves to be useful, we can add it later.
  return {
    name: name || GLOBAL_COMMANDS_GROUP_TITLE,
    items: items.filter(({ component }) => component !== 'invite_members'),
  };
};

export const linksReducer = (acc, menuItem) => {
  const trackingAttrs = ({ id, title }) => {
    return {
      extraAttrs: {
        'data-track-action': TRACKING_CLICK_COMMAND_PALETTE_ITEM,
        'data-track-label': id || TRACKING_UNKNOWN_ID,
        ...(id
          ? {}
          : {
              'data-track-extra': JSON.stringify({ title }),
            }),
      },
    };
  };

  acc.push({
    text: menuItem.title,
    keywords: menuItem.title,
    icon: menuItem.icon,
    href: menuItem.link,
    ...trackingAttrs(menuItem),
  });
  if (menuItem.items?.length) {
    const items = menuItem.items.map((item) => ({
      keywords: item.title,
      text: [menuItem.title, item.title].join(' > '),
      href: item.link,
      icon: menuItem.icon,
      ...trackingAttrs(item),
    }));

    /* eslint-disable-next-line no-param-reassign */
    acc = [...acc, ...items];
  }
  return acc;
};

export const fileMapper = (projectBlobPath, file) => {
  return {
    icon: 'doc-code',
    text: file,
    href: encodeSaferUrl(joinPaths(projectBlobPath, file)),
    extraAttrs: {
      'data-track-action': TRACKING_CLICK_COMMAND_PALETTE_ITEM,
      'data-track-label': 'file',
    },
  };
};

export const autocompleteQuery = ({ path, searchTerm, handle, projectId }) => {
  const query = omitBy(
    {
      term: searchTerm,
      project_id: projectId,
      filter: 'search',
      scope: SEARCH_SCOPE[handle],
    },
    isNil,
  );

  return `${path}?${objectToQuery(query)}`;
};
