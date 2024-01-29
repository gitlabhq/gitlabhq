import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { JS_TOGGLE_EXPAND_CLASS } from './constants';
import createStore from './components/global_search/store';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from './super_sidebar_collapsed_state_manager';
import SuperSidebar from './components/super_sidebar.vue';
import SuperSidebarToggle from './components/super_sidebar_toggle.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const getTrialStatusWidgetData = (sidebarData) => {
  if (sidebarData.trial_status_widget_data_attrs && sidebarData.trial_status_popover_data_attrs) {
    const {
      containerId,
      trialDaysUsed,
      trialDuration,
      navIconImagePath,
      percentageComplete,
      planName,
      plansHref,
      trialDiscoverPagePath,
    } = convertObjectPropsToCamelCase(sidebarData.trial_status_widget_data_attrs);

    const {
      daysRemaining,
      targetId,
      trialEndDate,
      namespaceId,
      userName,
      firstName,
      lastName,
      companyName,
      glmContent,
      createHandRaiseLeadPath,
      trackAction,
      trackLabel,
    } = convertObjectPropsToCamelCase(sidebarData.trial_status_popover_data_attrs);

    return {
      showTrialStatusWidget: true,
      containerId,
      trialDaysUsed: Number(trialDaysUsed),
      trialDuration: Number(trialDuration),
      navIconImagePath,
      percentageComplete: Number(percentageComplete),
      planName,
      plansHref,
      daysRemaining,
      targetId,
      createHandRaiseLeadPath,
      trackAction,
      trackLabel,
      trialEndDate: new Date(trialEndDate),
      trialDiscoverPagePath,
      user: { namespaceId, userName, firstName, lastName, companyName, glmContent },
    };
  }
  return { showTrialStatusWidget: false };
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

  const { searchPath, issuesPath, mrPath, autocompletePath, searchContext } = searchData;
  const isImpersonating = parseBoolean(sidebarData.is_impersonating);

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
      searchContext,
      projectFilesPath,
      projectBlobPath,
      projectsPath,
      groupsPath,
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
