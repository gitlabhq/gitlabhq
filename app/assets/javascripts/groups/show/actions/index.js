import Vue from 'vue';
import GroupActionsApp from '~/groups/show/actions/components/app.vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { formatGroup } from '~/groups/show/actions/formatter';

export const initGroupActions = () => {
  const el = document.querySelector('#js-group-more-actions-dropdown');

  if (!el) return null;

  const { dashboardPath, canWithdrawAccessRequest, canRequestAccess } =
    convertObjectPropsToCamelCase(el.dataset);

  const baseGroup = JSON.parse(el.dataset.group);
  const group = formatGroup(baseGroup, {
    canWithdrawAccessRequest: parseBoolean(canWithdrawAccessRequest),
    canRequestAccess: parseBoolean(canRequestAccess),
  });

  return new Vue({
    el,
    name: 'GroupActionsApp',
    provide: {
      triggerDeleteLocation: 'header',
      triggerRestoreLocation: 'header',
    },
    render: (createElement) => createElement(GroupActionsApp, { props: { group, dashboardPath } }),
  });
};
