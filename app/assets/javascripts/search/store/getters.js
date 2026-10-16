import { intersection, difference } from 'lodash-es';
import { parseBoolean } from '@gitlab/frontend-utils';
import {
  formatSearchResultCount,
  addCountOverLimit,
  injectRegexSearch,
  scopeCrawler,
  modifySearchQuery,
} from '~/search/store/utils';

import {
  SCOPE_ISSUES,
  SCOPE_WORK_ITEMS,
  SCOPE_MERGE_REQUESTS,
  SCOPE_BLOB,
  SCOPE_PROJECTS,
  SCOPE_GROUPS,
  SCOPE_NOTES,
  SCOPE_COMMITS,
  SCOPE_MILESTONES,
  SCOPE_WIKI_BLOBS,
  SEARCH_TYPE_ADVANCED,
  SEARCH_TYPE_ZOEKT,
  WORK_ITEM_TYPE_FILTER_PARAM,
  STATE_FILTER_PARAM,
  CONFIDENTAL_FILTER_PARAM,
  AUTHOR_PARAM,
  NOT_AUTHOR_PARAM,
  SOURCE_BRANCH_PARAM,
  NOT_SOURCE_BRANCH_PARAM,
  TARGET_BRANCH_PARAM,
  NOT_TARGET_BRANCH_PARAM,
  LABEL_FILTER_PARAM,
  LABEL_AGREGATION_NAME,
  LANGUAGE_FILTER_PARAM,
  INCLUDE_ARCHIVED_FILTER_PARAM,
  EXCLUDE_FORKS_FILTER_PARAM,
  WORK_ITEM_TYPE_AGGREGATION_NAME,
} from '~/search/sidebar/constants';

import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY, ICON_MAP } from './constants';

const BOOLEAN_SIDEBAR_PARAMS = [INCLUDE_ARCHIVED_FILTER_PARAM, EXCLUDE_FORKS_FILTER_PARAM];

const queryLabelFilters = (state) => state?.query?.[LABEL_FILTER_PARAM] || [];
const urlQueryLabelFilters = (state) => state?.urlQuery?.[LABEL_FILTER_PARAM] || [];

const appliedSelectedLabelsKeys = (state) =>
  intersection(urlQueryLabelFilters(state), queryLabelFilters(state));

const unselectedLabelsKeys = (state) =>
  difference(urlQueryLabelFilters(state), queryLabelFilters(state));

const unappliedNewLabelKeys = (state) => {
  return state?.query?.[LABEL_FILTER_PARAM]?.filter(
    (label) => !urlQueryLabelFilters(state)?.includes(label),
  );
};

export const queryLanguageFilters = (state) => {
  const language = state.query[LANGUAGE_FILTER_PARAM];

  if (!language) return [];

  return Array.isArray(language) ? language : [language];
};

export const queryWorkItemTypeFilters = ({ query: { type } }) => {
  if (!type) return [];
  return Array.isArray(type) ? type : [type];
};

export const frequentGroups = (state) => {
  return state.frequentItems[GROUPS_LOCAL_STORAGE_KEY];
};

export const frequentProjects = (state) => {
  return state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY];
};

export const languageAggregationBuckets = (state) => {
  return (
    state.aggregations.data.find((aggregation) => aggregation.name === LANGUAGE_FILTER_PARAM)
      ?.buckets || []
  );
};

export const labelAggregationBuckets = (state) => {
  return (
    state?.aggregations?.data?.find((aggregation) => aggregation.name === LABEL_AGREGATION_NAME)
      ?.buckets || []
  );
};

export const filteredLabels = (state) => {
  if (state.searchLabelString === '') {
    return labelAggregationBuckets(state);
  }
  return labelAggregationBuckets(state).filter((label) => {
    return label.title.toLowerCase().includes(state.searchLabelString.toLowerCase());
  });
};

export const filteredAppliedSelectedLabels = (state) =>
  filteredLabels(state)?.filter((label) => urlQueryLabelFilters(state)?.includes(label.title));

export const appliedSelectedLabels = (state) =>
  labelAggregationBuckets(state)?.filter((label) =>
    appliedSelectedLabelsKeys(state)?.includes(label.title),
  );

export const filteredUnselectedLabels = (state) =>
  filteredLabels(state)?.filter((label) => !urlQueryLabelFilters(state)?.includes(label.title));

export const unselectedLabels = (state) =>
  labelAggregationBuckets(state).filter((label) =>
    unselectedLabelsKeys(state)?.includes(label.title),
  );

export const unappliedNewLabels = (state) =>
  labelAggregationBuckets(state).filter((label) => {
    return unappliedNewLabelKeys(state)?.includes(label.title);
  });

export const currentScope = (state) => {
  return scopeCrawler(state.navigation);
};

export const searchNavigationLink = (item, state) => {
  const { link } = item;
  let newQueryParam = {};

  if (item.scope === SCOPE_BLOB) {
    newQueryParam = {
      ...injectRegexSearch(link, true),
    };
  }

  if (!state.query?.search) {
    newQueryParam.search = '*';
  }

  return modifySearchQuery(link, newQueryParam);
};

export const navigationItems = (state) =>
  Object.values(state.navigation).map((item, index) => {
    const navigation = {
      id: `menu-${item.scope}-${index}`,
      scope: item.scope,
      title: item.label,
      icon: ICON_MAP[item.scope] || '',
      link: searchNavigationLink(item, state),
      is_active: Boolean(item?.active),
      pill_count: item?.count
        ? `${formatSearchResultCount(item.count)}${addCountOverLimit(item.count)}`
        : '-',
    };

    return navigation;
  });

export const hasMissingProjectContext = (state) => !state?.projectInitialJson?.id;

export const isZoektCodeSearch = (state, getters) =>
  state.searchType === SEARCH_TYPE_ZOEKT && getters.currentScope === SCOPE_BLOB;

const isSidebarFilterApplied = (param, value) => {
  if (BOOLEAN_SIDEBAR_PARAMS.includes(param)) return parseBoolean(value);
  if (Array.isArray(value)) return value.length > 0;
  return Boolean(value);
};

// Mirrors which filters each scope's component in ~/search/sidebar/components renders.
export const sidebarFilterParams = (state, getters) => {
  const isAdvancedSearch = state.searchType === SEARCH_TYPE_ADVANCED;
  const archivedParams = getters.hasMissingProjectContext ? [INCLUDE_ARCHIVED_FILTER_PARAM] : [];
  const advancedParams = isAdvancedSearch
    ? [AUTHOR_PARAM, NOT_AUTHOR_PARAM, LABEL_FILTER_PARAM]
    : [];

  switch (getters.currentScope) {
    case SCOPE_ISSUES:
    case SCOPE_WORK_ITEMS: {
      const typeParams =
        getters.currentScope === SCOPE_WORK_ITEMS && getters.workItemTypes.length > 0
          ? [WORK_ITEM_TYPE_FILTER_PARAM]
          : [];

      return [
        ...typeParams,
        STATE_FILTER_PARAM,
        CONFIDENTAL_FILTER_PARAM,
        ...advancedParams,
        ...archivedParams,
      ];
    }
    case SCOPE_MERGE_REQUESTS: {
      const branchParams =
        !getters.hasMissingProjectContext || state.groupInitialJson?.id
          ? [
              SOURCE_BRANCH_PARAM,
              NOT_SOURCE_BRANCH_PARAM,
              TARGET_BRANCH_PARAM,
              NOT_TARGET_BRANCH_PARAM,
            ]
          : [];

      return [STATE_FILTER_PARAM, ...archivedParams, ...branchParams, ...advancedParams];
    }
    case SCOPE_BLOB: {
      if (state.searchType === SEARCH_TYPE_ZOEKT) {
        const forksParams = getters.hasMissingProjectContext ? [EXCLUDE_FORKS_FILTER_PARAM] : [];

        return [LANGUAGE_FILTER_PARAM, ...archivedParams, ...forksParams];
      }

      return isAdvancedSearch ? [LANGUAGE_FILTER_PARAM, ...archivedParams] : [];
    }
    case SCOPE_PROJECTS:
    case SCOPE_GROUPS:
      return [INCLUDE_ARCHIVED_FILTER_PARAM];
    case SCOPE_NOTES:
    case SCOPE_COMMITS:
    case SCOPE_MILESTONES:
    case SCOPE_WIKI_BLOBS:
      return archivedParams;
    default:
      return [];
  }
};

export const hasAppliedFilters = (state, getters) => {
  const appliedQuery = getters.isZoektCodeSearch ? state.query : state.urlQuery;

  return getters.sidebarFilterParams.some((param) =>
    isSidebarFilterApplied(param, appliedQuery?.[param]),
  );
};

export const workItemTypes = (state) => state.workItemTypes || [];

export const workItemTypeAggregationBuckets = (state) => {
  return (
    state?.aggregations?.data?.find(
      (aggregation) => aggregation.name === WORK_ITEM_TYPE_AGGREGATION_NAME,
    )?.buckets || []
  );
};
