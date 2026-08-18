import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import TimelogsApp from './components/timelogs_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-timelogs-app');
  if (!el) {
    return false;
  }

  const { limitToHours, canReadAllResources, emptyStateSvgPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'TimelogsAppRoot',
    apolloProvider,
    component: TimelogsApp,
    props: {
      limitToHours: parseBoolean(limitToHours),
      canReadAllResources: parseBoolean(canReadAllResources),
      emptyStateSvgPath,
    },
  });
};
