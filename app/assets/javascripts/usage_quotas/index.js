import Vue from 'vue';
import { usageQuotasTabsMetadata as groupViewTabsMetadata } from 'ee_else_ce/usage_quotas/group_view_metadata';
import { usageQuotasTabsMetadata as profileViewTabsMetadata } from 'ee_else_ce/usage_quotas/profile_view_metadata';
import { usageQuotasTabsMetadata as projectViewTabsMetadata } from 'ee_else_ce/usage_quotas/project_view_metadata';
import UsageQuotasApp from './components/usage_quotas_app.vue';
import { GROUP_VIEW_TYPE, PROJECT_VIEW_TYPE, PROFILE_VIEW_TYPE } from './constants';

const getViewTabs = (viewType) => {
  if (viewType === GROUP_VIEW_TYPE) {
    return groupViewTabsMetadata;
  }

  if (viewType === PROJECT_VIEW_TYPE) {
    return projectViewTabsMetadata;
  }

  if (viewType === PROFILE_VIEW_TYPE) {
    return profileViewTabsMetadata;
  }

  return false;
};

export default (viewType) => {
  const el = document.querySelector('#js-usage-quotas-view');
  const tabs = getViewTabs(viewType);

  if (!el || !tabs) return false;

  return new Vue({
    el,
    name: 'UsageQuotasView',
    provide: {
      tabs,
    },
    render(createElement) {
      return createElement(UsageQuotasApp);
    },
  });
};
