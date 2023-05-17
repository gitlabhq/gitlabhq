import { omitBy, isNil } from 'lodash';
import { objectToQuery } from '~/lib/utils/url_utility';
import {
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
  MSG_IN_ALL_GITLAB,
  PROJECTS_CATEGORY,
  GROUPS_CATEGORY,
  SEARCH_RESULTS_ORDER,
} from '~/vue_shared/global_search/constants';
import { getFormattedItem } from '../utils';

import {
  ICON_GROUP,
  ICON_SUBGROUP,
  ICON_PROJECT,
  SEARCH_SHORTCUTS_MIN_CHARACTERS,
} from '../constants';

export const searchQuery = (state) => {
  const query = omitBy(
    {
      search: state.search,
      nav_source: 'navbar',
      project_id: state.searchContext?.project?.id,
      group_id: state.searchContext?.group?.id,
      scope: state.searchContext?.scope,
      snippets: state.searchContext?.for_snippets ? true : null,
      search_code: state.searchContext?.code_search ? true : null,
      repository_ref: state.searchContext?.ref,
    },
    isNil,
  );

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const scopedIssuesPath = (state) => {
  if (state.searchContext?.project?.id && !state.searchContext?.project_metadata?.issues_path) {
    return false;
  }

  return (
    state.searchContext?.project_metadata?.issues_path ||
    state.searchContext?.group_metadata?.issues_path ||
    state.issuesPath
  );
};

export const scopedMRPath = (state) => {
  return (
    state.searchContext?.project_metadata?.mr_path ||
    state.searchContext?.group_metadata?.mr_path ||
    state.mrPath
  );
};

export const defaultSearchOptions = (state, getters) => {
  const userName = gon.current_username;

  const issues = [
    {
      text: MSG_ISSUES_ASSIGNED_TO_ME,
      href: `${getters.scopedIssuesPath}/?assignee_username=${userName}`,
    },
    {
      text: MSG_ISSUES_IVE_CREATED,
      href: `${getters.scopedIssuesPath}/?author_username=${userName}`,
    },
  ];

  const mergeRequests = [
    {
      text: MSG_MR_ASSIGNED_TO_ME,
      href: `${getters.scopedMRPath}/?assignee_username=${userName}`,
    },
    {
      text: MSG_MR_IM_REVIEWER,
      href: `${getters.scopedMRPath}/?reviewer_username=${userName}`,
    },
    {
      text: MSG_MR_IVE_CREATED,
      href: `${getters.scopedMRPath}/?author_username=${userName}`,
    },
  ];
  return [...(getters.scopedIssuesPath ? issues : []), ...mergeRequests];
};

export const projectUrl = (state) => {
  const query = omitBy(
    {
      search: state.search,
      nav_source: 'navbar',
      project_id: state.searchContext?.project?.id,
      group_id: state.searchContext?.group?.id,
      scope: state.searchContext?.scope,
      snippets: state.searchContext?.for_snippets ? true : null,
      search_code: state.searchContext?.code_search ? true : null,
      repository_ref: state.searchContext?.ref,
    },
    isNil,
  );

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const groupUrl = (state) => {
  const query = omitBy(
    {
      search: state.search,
      nav_source: 'navbar',
      group_id: state.searchContext?.group?.id,
      scope: state.searchContext?.scope,
      snippets: state.searchContext?.for_snippets ? true : null,
      search_code: state.searchContext?.code_search ? true : null,
      repository_ref: state.searchContext?.ref,
    },
    isNil,
  );

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const allUrl = (state) => {
  const query = omitBy(
    {
      search: state.search,
      nav_source: 'navbar',
      scope: state.searchContext?.scope,
      snippets: state.searchContext?.for_snippets ? true : null,
      search_code: state.searchContext?.code_search ? true : null,
      repository_ref: state.searchContext?.ref,
    },
    isNil,
  );

  return `${state.searchPath}?${objectToQuery(query)}`;
};

export const scopedSearchOptions = (state, getters) => {
  const items = [];

  if (state.searchContext?.project) {
    items.push({
      text: 'scoped-in-project',
      scope: state.searchContext.project?.name || '',
      scopeCategory: PROJECTS_CATEGORY,
      icon: ICON_PROJECT,
      href: getters.projectUrl,
    });
  }

  if (state.searchContext?.group) {
    items.push({
      text: 'scoped-in-group',
      scope: state.searchContext.group?.name || '',
      scopeCategory: GROUPS_CATEGORY,
      icon: state.searchContext.group?.full_name?.includes('/') ? ICON_SUBGROUP : ICON_GROUP,
      href: getters.groupUrl,
    });
  }

  items.push({
    text: 'scoped-in-all',
    description: MSG_IN_ALL_GITLAB,
    href: getters.allUrl,
  });

  return items;
};

export const scopedSearchGroup = (state, getters) => {
  const items = getters.scopedSearchOptions?.length ? getters.scopedSearchOptions.slice(1) : [];
  return { items };
};

export const autocompleteGroupedSearchOptions = (state) => {
  const groupedOptions = {};
  const results = [];

  state.autocompleteOptions.forEach((item) => {
    const group = groupedOptions[item.category];
    const formattedItem = getFormattedItem(item, state.searchContext);

    if (group) {
      group.items.push(formattedItem);
    } else {
      groupedOptions[item.category] = {
        name: formattedItem.category,
        items: [formattedItem],
      };

      results.push(groupedOptions[formattedItem.category]);
    }
  });

  return results.sort(
    (a, b) => SEARCH_RESULTS_ORDER.indexOf(a.name) - SEARCH_RESULTS_ORDER.indexOf(b.name),
  );
};

export const searchOptions = (state, getters) => {
  if (!state.search) {
    return getters.defaultSearchOptions;
  }

  const sortedAutocompleteOptions = Object.values(getters.autocompleteGroupedSearchOptions).reduce(
    (items, group) => {
      return [...items, ...group.items];
    },
    [],
  );

  if (state.search?.length <= SEARCH_SHORTCUTS_MIN_CHARACTERS) {
    return sortedAutocompleteOptions;
  }

  return (getters.scopedSearchOptions ?? []).concat(sortedAutocompleteOptions);
};
