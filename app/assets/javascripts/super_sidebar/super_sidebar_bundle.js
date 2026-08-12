import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { CONTEXT_NAMESPACE_GROUPS } from './constants';
import createStore from './components/global_search/store';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from './super_sidebar_collapsed_state_manager';
import SuperSidebar from './components/super_sidebar.vue';
import SuperTopbar from './components/super_topbar.vue';

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

export const getSuperSidebarData = () => {
  const el = document.querySelector('.js-super-sidebar');
  if (!el) return false;

  const { sidebar, commandPalette, isSaas } = el.dataset;
  const sidebarData = JSON.parse(sidebar);
  const searchData = convertObjectPropsToCamelCase(sidebarData.search);
  const { searchContext } = searchData;
  const currentPath = sidebarData?.current_context?.item?.fullPath;
  const commandPaletteData = JSON.parse(commandPalette);
  const projectFilesPath = commandPaletteData.project_files_url;
  const projectBlobPath = commandPaletteData.project_blob_url;
  const commandPaletteCommands = sidebarData.create_new_menu_groups || [];
  const commandPaletteLinks = convertObjectPropsToCamelCase(sidebarData.current_menu_items || []);
  const isImpersonating = parseBoolean(sidebarData.is_impersonating);
  const isGroup = Boolean(sidebarData.current_context?.namespace === CONTEXT_NAMESPACE_GROUPS);

  return {
    el,
    currentPath,
    isSaas,
    sidebarData,
    searchContext,
    projectFilesPath,
    projectBlobPath,
    commandPaletteCommands,
    commandPaletteLinks,
    isImpersonating,
    isGroup,
  };
};

export const initSuperSidebar = ({
  el,
  currentPath,
  isSaas,
  sidebarData,
  searchContext,
  projectFilesPath,
  projectBlobPath,
  commandPaletteCommands,
  commandPaletteLinks,
  isImpersonating,
  isGroup,
}) => {
  if (!el) return false;

  bindSuperSidebarCollapsedEvents();
  initSuperSidebarCollapsedState();

  return initVueApp({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider,
    provide: {
      currentPath,
      isImpersonating,
      ...getTrialStatusWidgetData(sidebarData),
      commandPaletteCommands,
      commandPaletteLinks,
      searchContext,
      projectFilesPath,
      projectBlobPath,
      resourceId: sidebarData.current_context?.item?.id,
      aiSearchAvailable: parseBoolean(sidebarData.ai_search_available),
      fullPath: sidebarData.work_items?.full_path,
      isGroup,
      isSaas: parseBoolean(isSaas),
    },
    store: createStore({
      searchContext,
      search: '',
    }),
    component: SuperSidebar,
    props: {
      sidebarData,
    },
  });
};

/**
 * This init function duplicates the args of `initSuperSidebar` for now.
 * TODO: When we clean up the `paneled_view` feature flag, we should remove the unused args from
 * both functions.
 */
export const initSuperTopbar = ({
  sidebarData,
  searchContext,
  projectFilesPath,
  projectBlobPath,
  commandPaletteCommands,
  commandPaletteLinks,
  isImpersonating,
  isGroup,
  isSaas,
}) => {
  const el = document.querySelector('.js-super-topbar');
  if (!el) return false;

  return initVueApp({
    el,
    name: 'SuperTopbarRoot',
    apolloProvider,
    provide: {
      isImpersonating,
      commandPaletteCommands,
      commandPaletteLinks,
      searchContext,
      projectFilesPath,
      projectBlobPath,
      resourceId: sidebarData.current_context?.item?.id,
      aiSearchAvailable: parseBoolean(sidebarData.ai_search_available),
      fullPath: sidebarData.work_items?.full_path,
      isGroup,
      isSaas: parseBoolean(isSaas),
    },
    store: createStore({
      searchContext,
      search: '',
    }),
    component: SuperTopbar,
    props: {
      sidebarData,
    },
  });
};
