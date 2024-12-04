import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PlannerRoleBanner from './components/planner_role_banner.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const EXPIRY_DATE = '2025-06-14';

export const initPlannerRoleBanner = () => {
  const expiryDate = new Date(EXPIRY_DATE);
  if (Date.now() > expiryDate) {
    return null;
  }

  const el = document.getElementById('js-planner-role-banner');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'PlannerRoleBannerRoot',
    apolloProvider,
    render(h) {
      return h(PlannerRoleBanner);
    },
  });
};
