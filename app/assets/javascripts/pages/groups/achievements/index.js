import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AchievementsApp from '~/achievements/components/achievements_app.vue';
import routes from '~/achievements/routes';

Vue.use(VueApollo);
Vue.use(VueRouter);

const init = () => {
  const el = document.getElementById('js-achievements-app');

  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { basePath, viewModel } = el.dataset;
  const provide = JSON.parse(viewModel);

  const router = new VueRouter({
    base: basePath,
    mode: 'history',
    routes,
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    provide: convertObjectPropsToCamelCase(provide),
    render(createElement) {
      return createElement(AchievementsApp);
    },
  });
};

init();
