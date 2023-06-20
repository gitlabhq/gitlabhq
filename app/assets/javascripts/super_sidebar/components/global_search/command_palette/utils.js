import { isNil, omitBy } from 'lodash';
import { objectToQuery } from '~/lib/utils/url_utility';
import { SEARCH_SCOPE } from './constants';

export const commandMapper = ({ name, items }) => {
  // TODO: we filter out invite_members for now, because it is complicated to add the invite members modal here
  // and is out of scope for the basic command palette items. If it proves to be useful, we can add it later.
  return {
    name,
    items: items.filter(({ component }) => component !== 'invite_members'),
  };
};

export const linksReducer = (acc, menuItem) => {
  acc.push({
    text: menuItem.title,
    keywords: menuItem.title,
    icon: menuItem.icon,
    href: menuItem.link,
  });
  if (menuItem.items?.length) {
    const items = menuItem.items.map(({ title, link }) => ({
      keywords: title,
      text: [menuItem.title, title].join(' > '),
      href: link,
      icon: menuItem.icon,
    }));

    /* eslint-disable-next-line no-param-reassign */
    acc = [...acc, ...items];
  }
  return acc;
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
