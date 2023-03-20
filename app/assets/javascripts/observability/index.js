import Vue from 'vue';
import VueRouter from 'vue-router';

import ObservabilityApp from './components/observability_app.vue';
import { SKELETON_VARIANTS_BY_ROUTE } from './constants';

Vue.use(VueRouter);

export default () => {
  const el = document.getElementById('js-observability-app');

  if (!el) return false;

  const router = new VueRouter({
    mode: 'history',
  });

  return new Vue({
    el,
    router,
    computed: {
      skeletonVariant() {
        const [, variant] =
          Object.entries(SKELETON_VARIANTS_BY_ROUTE).find(([path]) =>
            this.$route.path.endsWith(path),
          ) || [];

        return variant;
      },
    },
    methods: {
      routeUpdateHandler(payload) {
        const isNewObservabilityPath = this.$route?.query?.observability_path !== payload?.url;

        const shouldNotHandleMessage = !payload.url || !isNewObservabilityPath;

        if (shouldNotHandleMessage) {
          return;
        }

        // this will update the `observability_path` query param on each route change inside Observability UI
        this.$router.replace({
          name: this.$route?.pathname,
          query: { ...this.$route.query, observability_path: payload.url },
        });
      },
    },
    render(h) {
      return h(ObservabilityApp, {
        props: {
          observabilityIframeSrc: el.dataset.observabilityIframeSrc,
          skeletonVariant: this.skeletonVariant,
        },
        on: {
          'route-update': (payload) => this.routeUpdateHandler(payload),
        },
      });
    },
  });
};
