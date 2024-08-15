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

Vue.use(GlToast);
Vue.use(VueApollo);

const getTrialStatusWidgetData = (sidebarData) => {
  if (sidebarData.trial_status_widget_data_attrs && sidebarData.trial_status_popover_data_attrs) {
    const {
      trialDaysUsed,
      trialDuration,
      navIconImagePath,
      percentageComplete,
      planName,
      plansHref,
      trialDiscoverPagePath,
    } = convertObjectPropsToCamelCase(sidebarData.trial_status_widget_data_attrs);

    const { daysRemaining, trialEndDate } = convertObjectPropsToCamelCase(
      sidebarData.trial_status_popover_data_attrs,
    );

    return {
      showTrialStatusWidget: true,
      showDuoProTrialStatusWidget: false,
      trialDaysUsed: Number(trialDaysUsed),
      trialDuration: Number(trialDuration),
      navIconImagePath,
      percentageComplete: Number(percentageComplete),
      planName,
      plansHref,
      daysRemaining,
      trialEndDate: new Date(trialEndDate),
      trialDiscoverPagePath,
    };
  }

  if (
    sidebarData.duo_pro_trial_status_widget_data_attrs &&
    sidebarData.duo_pro_trial_status_popover_data_attrs
  ) {
    const {
      trialDaysUsed,
      trialDuration,
      percentageComplete,
      groupId,
      featureId,
      dismissEndpoint,
    } = convertObjectPropsToCamelCase(sidebarData.duo_pro_trial_status_widget_data_attrs);

    const { daysRemaining, trialEndDate, purchaseNowUrl, learnAboutButtonUrl } =
      convertObjectPropsToCamelCase(sidebarData.duo_pro_trial_status_popover_data_attrs);

    return {
      showDuoProTrialStatusWidget: true,
      showTrialStatusWidget: false,
      trialDaysUsed: Number(trialDaysUsed),
      trialDuration: Number(trialDuration),
      percentageComplete: Number(percentageComplete),
      groupId,
      featureId,
      dismissEndpoint,
      daysRemaining,
      trialEndDate: new Date(trialEndDate),
      purchaseNowUrl,
      learnAboutButtonUrl,
    };
  }

  return { showTrialStatusWidget: false, showDuoProTrialStatusWidget: false };
};

export const initSuperSidebar = () => {
  const el = document.querySelector('.js-super-sidebar');

  if (!el) return false;

  const { rootPath, sidebar, forceDesktopExpandedSidebar, commandPalette } = el.dataset;

  bindSuperSidebarCollapsedEvents(forceDesktopExpandedSidebar);
  initSuperSidebarCollapsedState(parseBoolean(forceDesktopExpandedSidebar));

  const sidebarData = JSON.parse(sidebar);
  const searchData = convertObjectPropsToCamelCase(sidebarData.search);

  const projectsPath = sidebarData.projects_path;
  const groupsPath = sidebarData.groups_path;

  const commandPaletteData = JSON.parse(commandPalette);
  const projectFilesPath = commandPaletteData.project_files_url;
  const projectBlobPath = commandPaletteData.project_blob_url;
  const commandPaletteCommands = sidebarData.create_new_menu_groups || [];
  const commandPaletteLinks = convertObjectPropsToCamelCase(sidebarData.current_menu_items || []);
  const contextSwitcherLinks = sidebarData.context_switcher_links;

  const { searchPath, issuesPath, mrPath, autocompletePath, settingsPath, searchContext } =
    searchData;
  const isImpersonating = parseBoolean(sidebarData.is_impersonating);

  const isGroup = Boolean(sidebarData.current_context?.namespace === CONTEXT_NAMESPACE_GROUPS);

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider,
    provide: {
      rootPath,
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
