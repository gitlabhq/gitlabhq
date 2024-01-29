import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import StarCount from './components/star_count.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const containers = document.querySelectorAll('.js-vue-star-count');

  if (containers.length === 0) {
    return false;
  }

  return containers.forEach((el) => {
    const { containerClass, projectPath, projectId, starCount, starred, starrersPath } = el.dataset;

    return new Vue({
      el,
      provide: {
        containerClass,
        starred: starred !== undefined,
        starCount,
        projectId,
        projectPath,
        starrersPath,
      },
      render(h) {
        return h(StarCount);
      },
      apolloProvider,
    });
  });
};
