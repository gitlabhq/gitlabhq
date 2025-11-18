import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { getApolloProvider } from '~/issues/list/issue_client';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { JS_TOGGLE_EXPAND_CLASS, CONTEXT_NAMESPACE_GROUPS } from './constants';
import createStore from './components/global_search/store';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from './super_sidebar_collapsed_state_manager';
import SuperSidebar from './components/super_sidebar.vue';
import SuperTopbar from './components/super_topbar.vue';
import SuperSidebarToggle from './components/super_sidebar_toggle.vue';

export { initPageBreadcrumbs } from './super_sidebar_breadcrumbs';

Vue.use(GlToast);
Vue.use(VueApollo);

const getTrialStatusWidgetData = (sidebarData) => {
  if (sidebarData.trial_widget_data_attrs) {
    const {
      trialType,
      daysRemaining,
      percentageComplete,
      groupId,
      trialDiscoverPagePath,
      purchaseNowUrl,
      featureId,
    } = convertObjectPropsToCamelCase(sidebarData.trial_widget_data_attrs);

    return {
      showTrialWidget: true,
      trialType,
      daysRemaining: Number(daysRemaining),
      percentageComplete: Number(percentageComplete),
      groupId,
      trialDiscoverPagePath,
      purchaseNowUrl,
      featureId,
    };
  }

  return {
    showTrialWidget: false,
  };
};

const getDuoAgentPlatformWidgetData = (sidebarData) => {
  if (sidebarData.duoAgentWidgetProvide) {
    const { actionPath, stateProgression, initialState, contextualAttributes } =
      sidebarData.duoAgentWidgetProvide;

    return {
      showDuoAgentPlatformWidget: true,
      actionPath,
      stateProgression,
      initialState,
      contextualAttributes,
    };
  }

  return {
    showDuoAgentPlatformWidget: false,
  };
};

export const getSuperSidebarData = () => {
  const el = document.querySelector('.js-super-sidebar');
  if (!el) return false;

  const { rootPath, sidebar, forceDesktopExpandedSidebar, commandPalette, isSaas } = el.dataset;
  const sidebarData = JSON.parse(sidebar);
  const searchData = convertObjectPropsToCamelCase(sidebarData.search);
  const { searchPath, issuesPath, mrPath, autocompletePath, settingsPath, searchContext } =
    searchData;
  const currentPath = sidebarData?.current_context?.item?.fullPath;
  const projectsPath = sidebarData.projects_path;
  const groupsPath = sidebarData.groups_path;
  const commandPaletteData = JSON.parse(commandPalette);
  const projectFilesPath = commandPaletteData.project_files_url;
  const projectBlobPath = commandPaletteData.project_blob_url;
  const commandPaletteCommands = sidebarData.create_new_menu_groups || [];
  const commandPaletteLinks = convertObjectPropsToCamelCase(sidebarData.current_menu_items || []);
  const contextSwitcherLinks = sidebarData.context_switcher_links;
  const isImpersonating = parseBoolean(sidebarData.is_impersonating);
  const isGroup = Boolean(sidebarData.current_context?.namespace === CONTEXT_NAMESPACE_GROUPS);

  const { projectStudioEnabled, projectStudioAvailable } = document.body.dataset;

  return {
    el,
    rootPath,
    currentPath,
    forceDesktopExpandedSidebar,
    isSaas,
    sidebarData,
    searchPath,
    issuesPath,
    mrPath,
    autocompletePath,
    settingsPath,
    searchContext,
    projectsPath,
    groupsPath,
    projectFilesPath,
    projectBlobPath,
    commandPaletteCommands,
    commandPaletteLinks,
    contextSwitcherLinks,
    isImpersonating,
    isGroup,
    projectStudioEnabled: parseBoolean(projectStudioEnabled),
    projectStudioAvailable: parseBoolean(projectStudioAvailable),
  };
};

export const initSuperSidebar = async ({
  el,
  rootPath,
  currentPath,
  forceDesktopExpandedSidebar,
  isSaas,
  sidebarData,
  searchPath,
  issuesPath,
  mrPath,
  autocompletePath,
  settingsPath,
  searchContext,
  projectsPath,
  groupsPath,
  projectFilesPath,
  projectBlobPath,
  commandPaletteCommands,
  commandPaletteLinks,
  contextSwitcherLinks,
  isImpersonating,
  isGroup,
  projectStudioEnabled,
  projectStudioAvailable,
}) => {
  if (!el) return false;

  bindSuperSidebarCollapsedEvents(forceDesktopExpandedSidebar);
  initSuperSidebarCollapsedState(parseBoolean(forceDesktopExpandedSidebar));

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider: await getApolloProvider(),
    provide: {
      rootPath,
      currentPath,
      isImpersonating,
      ...getTrialStatusWidgetData(sidebarData),
      ...getDuoAgentPlatformWidgetData(sidebarData),
      commandPaletteCommands,
      commandPaletteLinks,
      contextSwitcherLinks,
      autocompletePath,
      settingsPath,
      searchContext,
      projectFilesPath,
      projectBlobPath,
      projectsPath,
      groupsPath,
      groupPath: groupsPath,
      fullPath: sidebarData.work_items?.full_path,
      hasIssuableHealthStatusFeature: sidebarData.work_items?.has_issuable_health_status_feature,
      hasIssueWeightsFeature: sidebarData.work_items?.has_issue_weights_feature,
      hasIterationsFeature: sidebarData.work_items?.has_iterations_feature,
      issuesListPath: sidebarData.work_items?.issues_list_path,
      canAdminLabel: parseBoolean(sidebarData.work_items?.can_admin_label),
      labelsManagePath: sidebarData.work_items?.labels_manage_path,
      workItemPlanningViewEnabled: parseBoolean(
        sidebarData.work_items?.work_item_planning_view_enabled,
      ),
      isGroup,
      isSaas: parseBoolean(isSaas),
      projectStudioEnabled,
      projectStudioAvailable,
    },
    store: createStore({
      searchPath,
      issuesPath,
      mrPath,
      autocompletePath,
      searchContext,
      search: '',
    }),
    render(h) {
      return h(SuperSidebar, {
        props: {
          sidebarData,
        },
      });
    },
  });
};

/**
 * Guard against multiple instantiations, since the js-* class is persisted
 * in the Vue component.
 */
let toggleInstantiated = false;

export const initSuperSidebarToggle = () => {
  const el = document.querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`);

  if (!el || toggleInstantiated) return false;

  toggleInstantiated = true;

  return new Vue({
    el,
    name: 'SuperSidebarToggleRoot',
    render(h) {
      // Copy classes from HAML-defined button to ensure same positioning,
      // including JS_TOGGLE_EXPAND_CLASS.
      return h(SuperSidebarToggle, { class: el.className });
    },
  });
};

/**
 * This init function duplicates the args of `initSuperSidebar` for now.
 * TODO: When we clean up the `paneled_view` feature flag, we should remove the unused args from
 * both functions.
 */
export const initSuperTopbar = async ({
  rootPath,
  sidebarData,
  searchPath,
  issuesPath,
  mrPath,
  autocompletePath,
  settingsPath,
  searchContext,
  projectsPath,
  groupsPath,
  projectFilesPath,
  projectBlobPath,
  commandPaletteCommands,
  commandPaletteLinks,
  contextSwitcherLinks,
  isImpersonating,
  isGroup,
  isSaas,
  projectStudioEnabled,
  projectStudioAvailable,
}) => {
  const el = document.querySelector('.js-super-topbar');
  if (!el) return false;

  return new Vue({
    el,
    apolloProvider: await getApolloProvider(),
    provide: {
      rootPath,
      isImpersonating,
      commandPaletteCommands,
      commandPaletteLinks,
      contextSwitcherLinks,
      autocompletePath,
      settingsPath,
      searchContext,
      projectFilesPath,
      projectBlobPath,
      projectsPath,
      groupsPath,
      groupPath: groupsPath,
      fullPath: sidebarData.work_items?.full_path,
      canAdminLabel: parseBoolean(sidebarData.work_items?.can_admin_label),
      workItemPlanningViewEnabled: parseBoolean(
        sidebarData.work_items?.work_item_planning_view_enabled,
      ),
      isGroup,
      isSaas: parseBoolean(isSaas),
      projectStudioEnabled,
      projectStudioAvailable,
    },
    store: createStore({
      searchPath,
      issuesPath,
      mrPath,
      autocompletePath,
      searchContext,
      search: '',
    }),
    render(h) {
      return h(SuperTopbar, {
        props: {
          sidebarData,
        },
      });
    },
  });
};
