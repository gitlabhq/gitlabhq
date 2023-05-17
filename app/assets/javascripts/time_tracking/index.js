import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import TimelogsApp from './components/timelogs_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-timelogs-app');
  if (!el) {
    return false;
  }

  const { limitToHours } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(TimelogsApp, {
        props: {
          limitToHours: parseBoolean(limitToHours),
        },
      });
    },
  });
};
