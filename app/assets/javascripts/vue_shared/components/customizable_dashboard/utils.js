import produce from 'immer';
import isEmpty from 'lodash/isEmpty';
import uniqueId from 'lodash/uniqueId';
import { queryToObject } from '~/lib/utils/url_utility';
import { formatDate, newDate } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import { humanize } from '~/lib/utils/text_utility';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
  parseBoolean,
  cloneWithoutReferences,
} from '~/lib/utils/common_utils';
import getAllCustomizableDashboardsQuery from './graphql/queries/get_all_customizable_dashboards.query.graphql';
import getCustomizableDashboardQuery from './graphql/queries/get_customizable_dashboard.query.graphql';
import { TYPENAME_ANALYTICS_DASHBOARD_PANEL } from './graphql/constants';
import {
  DASHBOARD_SCHEMA_VERSION,
  VISUALIZATION_TYPE_DATA_TABLE,
  VISUALIZATION_TYPE_SINGLE_STAT,
  CATEGORY_SINGLE_STATS,
  CATEGORY_CHARTS,
  CATEGORY_TABLES,
} from './constants';
import {
  DATE_RANGE_OPTIONS,
  CUSTOM_DATE_RANGE_KEY,
  DEFAULT_SELECTED_OPTION_INDEX,
} from './filters/constants';

const isCustomOption = (option) => option && option === CUSTOM_DATE_RANGE_KEY;

export const getDateRangeOption = (optionKey) =>
  DATE_RANGE_OPTIONS.find(({ key }) => key === optionKey);

export const dateRangeOptionToFilter = ({ startDate, endDate, key }) => ({
  startDate,
  endDate,
  dateRangeOption: key,
});

const DEFAULT_FILTER = dateRangeOptionToFilter(DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX]);

export const buildDefaultDashboardFilters = (queryString) => {
  const {
    dateRangeOption: optionKey,
    startDate,
    endDate,
    filterAnonUsers,
  } = convertObjectPropsToCamelCase(queryToObject(queryString, { gatherArrays: true }));

  const customDateRange = isCustomOption(optionKey);

  return {
    ...DEFAULT_FILTER,
    // Override default filter with user defined option
    ...(optionKey && dateRangeOptionToFilter(getDateRangeOption(optionKey))),
    // Override date range when selected option is custom date range
    ...(customDateRange && { startDate: newDate(startDate) }),
    ...(customDateRange && { endDate: newDate(endDate) }),
    filterAnonUsers: parseBoolean(filterAnonUsers),
  };
};

export const filtersToQueryParams = ({ dateRangeOption, startDate, endDate, filterAnonUsers }) => {
  const customDateRange = isCustomOption(dateRangeOption);

  return convertObjectPropsToSnakeCase({
    dateRangeOption,
    // Clear the date range unless the custom date range is selected
    startDate: customDateRange ? formatDate(startDate, ISO_SHORT_FORMAT) : null,
    endDate: customDateRange ? formatDate(endDate, ISO_SHORT_FORMAT) : null,
    // Clear the anon users filter unless truthy
    filterAnonUsers: filterAnonUsers || null,
  });
};

export const isEmptyPanelData = (visualizationType, data) => {
  if (visualizationType === 'SingleStat') {
    // SingleStat visualizations currently do not show an empty state, and instead show a default "0" value
    // This will be revisited: https://gitlab.com/gitlab-org/gitlab/-/issues/398792
    return false;
  }
  return isEmpty(data);
};

/**
 * Validator for the availableVisualizations property
 */
export const availableVisualizationsValidator = ({ loading, hasError, visualizations }) => {
  return (
    typeof loading === 'boolean' && typeof hasError === 'boolean' && Array.isArray(visualizations)
  );
};

/**
 * Get the category key for visualizations by their type. Default is "charts".
 */
export const getVisualizationCategory = (visualization) => {
  if (visualization.type === VISUALIZATION_TYPE_SINGLE_STAT) {
    return CATEGORY_SINGLE_STATS;
  }
  if (visualization.type === VISUALIZATION_TYPE_DATA_TABLE) {
    return CATEGORY_TABLES;
  }
  return CATEGORY_CHARTS;
};

export const getUniquePanelId = () => uniqueId('panel-');

/**
 * Maps a full hydrated dashboard (including GraphQL __typenames, and full visualization definitions) into a slimmed down version that complies with the dashboard schema definition
 */
export const getDashboardConfig = (hydratedDashboard) => {
  const { __typename: dashboardTypename, userDefined, slug, ...dashboardRest } = hydratedDashboard;
  return {
    ...dashboardRest,
    version: DASHBOARD_SCHEMA_VERSION,
    panels: hydratedDashboard.panels.map((panel) => {
      const { __typename: panelTypename, id, ...panelRest } = panel;
      return {
        ...panelRest,
        queryOverrides: panel.queryOverrides ?? {},
        visualization: panel.visualization.slug,
      };
    }),
  };
};

/**
 * Updates a dashboard detail in cache from getProductAnalyticsDashboard:{slug}
 */
const updateDashboardDetailsApolloCache = ({
  apolloClient,
  dashboard,
  slug,
  fullPath,
  isProject,
  isGroup,
}) => {
  const getDashboardDetailsQuery = {
    query: getCustomizableDashboardQuery,
    variables: {
      fullPath,
      slug,
      isProject,
      isGroup,
    },
  };
  const sourceData = apolloClient.readQuery(getDashboardDetailsQuery);
  if (!sourceData) {
    // Dashboard details not yet in cache, must be a new dashboard, nothing to update
    return;
  }

  const data = produce(sourceData, (draftState) => {
    const { nodes } = isProject
      ? draftState.project.customizableDashboards
      : draftState.group.customizableDashboards;
    const updateIndex = nodes.findIndex((node) => node.slug === slug);

    if (updateIndex < 0) return;

    const updateNode = nodes[updateIndex];

    nodes.splice(updateIndex, 1, {
      ...updateNode,
      ...dashboard,
      panels: {
        ...updateNode.panels,
        nodes:
          dashboard.panels?.map((panel) => {
            const { id, ...panelRest } = panel;
            return { __typename: TYPENAME_ANALYTICS_DASHBOARD_PANEL, ...panelRest };
          }) || [],
      },
    });
  });

  apolloClient.writeQuery({
    ...getDashboardDetailsQuery,
    data,
  });
};

/**
 * Adds/updates a newly created dashboard to the dashboards list cache from getAllCustomizableDashboardsQuery
 */
const updateDashboardsListApolloCache = ({
  apolloClient,
  dashboardSlug,
  dashboard,
  fullPath,
  isProject,
  isGroup,
}) => {
  const getDashboardListQuery = {
    query: getAllCustomizableDashboardsQuery,
    variables: {
      fullPath,
      isProject,
      isGroup,
    },
  };
  const sourceData = apolloClient.readQuery(getDashboardListQuery);
  if (!sourceData) {
    // Dashboard list not yet loaded in cache, nothing to update
    return;
  }

  const data = produce(sourceData, (draftState) => {
    const { panels, ...dashboardWithoutPanels } = dashboard;
    const { nodes } = isProject
      ? draftState.project.customizableDashboards
      : draftState.group.customizableDashboards;

    const updateIndex = nodes.findIndex(({ slug }) => slug === dashboardSlug);

    // Add new dashboard if it doesn't exist
    if (updateIndex < 0) {
      nodes.push(dashboardWithoutPanels);
      return;
    }

    nodes.splice(updateIndex, 1, {
      ...nodes[updateIndex],
      ...dashboardWithoutPanels,
    });
  });

  apolloClient.writeQuery({
    ...getDashboardListQuery,
    data,
  });
};

export const updateApolloCache = ({
  apolloClient,
  slug,
  dashboard,
  fullPath,
  isProject,
  isGroup,
}) => {
  // TODO: modify to support removing dashboards from cache https://gitlab.com/gitlab-org/gitlab/-/issues/425513
  updateDashboardDetailsApolloCache({
    apolloClient,
    dashboard,
    slug,
    fullPath,
    isProject,
    isGroup,
  });
  updateDashboardsListApolloCache({ apolloClient, slug, dashboard, fullPath, isProject, isGroup });
};

const filterUndefinedValues = (obj) => {
  // eslint-disable-next-line no-unused-vars
  return Object.fromEntries(Object.entries(obj).filter(([_, value]) => value !== undefined));
};

/**
 * Parses a dashboard panel config into a GridStack item.
 */
export const parsePanelToGridItem = ({
  gridAttributes: { xPos, yPos, width, height, minHeight, minWidth, maxHeight, maxWidth },
  id,
  ...rest
}) =>
  // GridStack renders undefined layout values so we need to filter them out.
  filterUndefinedValues({
    x: xPos,
    y: yPos,
    w: width,
    h: height,
    minH: minHeight,
    minW: minWidth,
    maxH: maxHeight,
    maxW: maxWidth,
    id,
    props: {
      id,
      ...rest,
    },
  });

export const createNewVisualizationPanel = (visualization) => ({
  id: getUniquePanelId(),
  title: humanize(visualization.slug),
  gridAttributes: {
    width: 4,
    height: 3,
  },
  queryOverrides: {},
  options: {},
  visualization: cloneWithoutReferences({ ...visualization, errors: null }),
});
