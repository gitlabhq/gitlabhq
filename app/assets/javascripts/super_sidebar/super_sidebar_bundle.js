import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { initStatusTriggers } from '../header';
import { JS_TOGGLE_EXPAND_CLASS } from './constants';
import createStore from './components/global_search/store';
import {
  bindSuperSidebarCollapsedEvents,
  initSuperSidebarCollapsedState,
} from './super_sidebar_collapsed_state_manager';
import SuperSidebar from './components/super_sidebar.vue';
import SuperSidebarToggle from './components/super_sidebar_toggle.vue';

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
      trialEndDate: new Date(trialEndDate),
      user: { namespaceId, userName, firstName, lastName, companyName, glmContent },
    };
  }
  return { showTrialStatusWidget: false };
};

export const initSuperSidebar = () => {
  const el = document.querySelector('.js-super-sidebar');

  if (!el) return false;

  bindSuperSidebarCollapsedEvents();
  initSuperSidebarCollapsedState();

  const { rootPath, sidebar, toggleNewNavEndpoint } = el.dataset;
  const sidebarData = JSON.parse(sidebar);
  const searchData = convertObjectPropsToCamelCase(sidebarData.search);

  const { searchPath, issuesPath, mrPath, autocompletePath, searchContext } = searchData;
  const isImpersonating = parseBoolean(sidebarData.is_impersonating);

  return new Vue({
    el,
    name: 'SuperSidebarRoot',
    apolloProvider,
    provide: {
      rootPath,
      toggleNewNavEndpoint,
      isImpersonating,
      ...getTrialStatusWidgetData(sidebarData),
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

requestIdleCallback(initStatusTriggers);
