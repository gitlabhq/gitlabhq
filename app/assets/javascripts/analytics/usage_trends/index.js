import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import UsageTrendsApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
});

export default () => {
  const el = document.getElementById('js-usage-trends-app');

  if (!el) return false;

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(UsageTrendsApp);
    },
  });
};
