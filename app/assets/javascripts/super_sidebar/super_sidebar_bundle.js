import Vue from 'vue';
import { GlBreadcrumb, GlToast } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { staticBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { JS_TOGGLE_EXPAND_CLASS, CONTEXT_NAMESPACE_GROUPS } from './constants';
import createStore from './components/global_search/store';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from './super_sidebar_collapsed_state_manager';
import SuperSidebar from './components/super_sidebar.vue';
import SuperSidebarToggle from './components/super_sidebar_toggle.vue';
import AdvancedSearchModal from './components/global_search/components/global_search_header_app.vue';

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
      dismissEndpoint,
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
      dismissEndpoint,
    };
  }

  return {
    showTrialWidget: false,
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
  };
};

export const initSuperSidebar = ({
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
}) => {
  if (!el) return false;

  bindSuperSidebarCollapsedEvents(forceDesktopExpandedSidebar);
  initSuperSidebarCollapsedState(parseBoolean(forceDesktopExpandedSidebar));

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider,
    provide: {
      rootPath,
      currentPath,
      isImpersonating,
      ...getTrialStatusWidgetData(sidebarData),
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
      fullPath: sidebarData.work_items?.full_path,
      hasIssuableHealthStatusFeature: sidebarData.work_items?.has_issuable_health_status_feature,
      issuesListPath: sidebarData.work_items?.issues_list_path,
      canAdminLabel: parseBoolean(sidebarData.work_items?.can_admin_label),
      labelsManagePath: sidebarData.work_items?.labels_manage_path,
      isGroup,
      isSaas: parseBoolean(isSaas),
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

export function initPageBreadcrumbs() {
  const el = document.querySelector('#js-vue-page-breadcrumbs');
  if (!el) return false;
  const { breadcrumbsJson } = el.dataset;

  staticBreadcrumbs.items = JSON.parse(breadcrumbsJson);

  return new Vue({
    el,
    render(h) {
      return h(GlBreadcrumb, {
        props: staticBreadcrumbs,
      });
    },
  });
}

export function initAdvancedSearchModal({
  rootPath,
  isSaas,
  sidebarData,
  searchPath,
  issuesPath,
  mrPath,
  autocompletePath,
  searchContext,
  projectsPath,
  groupsPath,
  projectFilesPath,
  projectBlobPath,
  commandPaletteCommands,
  commandPaletteLinks,
  contextSwitcherLinks,
  isGroup,
}) {
  const el = document.querySelector('#js-advanced-search-modal');

  if (!el) return false;

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider,
    provide: {
      rootPath,
      commandPaletteCommands,
      commandPaletteLinks,
      contextSwitcherLinks,
      autocompletePath,
      searchContext,
      projectFilesPath,
      projectBlobPath,
      projectsPath,
      groupsPath,
      fullPath: sidebarData.work_items?.full_path,
      isGroup,
      isSaas: parseBoolean(isSaas),
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
      return h(AdvancedSearchModal);
    },
  });
}
