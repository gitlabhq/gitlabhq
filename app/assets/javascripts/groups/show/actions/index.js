import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import GroupActionsApp from '~/groups/show/actions/components/app.vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { formatGroup } from '~/groups/show/actions/formatter';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

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
    apolloProvider,
    provide: {
      triggerDeleteLocation: 'header',
      triggerRestoreLocation: 'header',
    },
    render: (createElement) => createElement(GroupActionsApp, { props: { group, dashboardPath } }),
  });
};
