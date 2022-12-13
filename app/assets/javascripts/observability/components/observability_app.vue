<script>
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

import { MESSAGE_EVENT_TYPE, OBSERVABILITY_ROUTES, SKELETON_VARIANT } from '../constants';
import ObservabilitySkeleton from './skeleton/index.vue';

export default {
  components: {
    ObservabilitySkeleton,
  },
  props: {
    observabilityIframeSrc: {
      type: String,
      required: true,
    },
  },
  computed: {
    iframeSrcWithParams() {
      return setUrlParams(
        { theme: darkModeEnabled() ? 'dark' : 'light', username: gon?.current_username },
        this.observabilityIframeSrc,
      );
    },
    getSkeletonVariant() {
      switch (this.$route.path) {
        case OBSERVABILITY_ROUTES.DASHBOARDS:
          return SKELETON_VARIANT.DASHBOARDS;
        case OBSERVABILITY_ROUTES.EXPLORE:
          return SKELETON_VARIANT.EXPLORE;
        case OBSERVABILITY_ROUTES.MANAGE:
          return SKELETON_VARIANT.MANAGE;
        default:
          return SKELETON_VARIANT.DASHBOARDS;
      }
    },
  },
  mounted() {
    window.addEventListener('message', this.messageHandler);
  },
  destroyed() {
    window.removeEventListener('message', this.messageHandler);
  },
  methods: {
    messageHandler(e) {
      const isExpectedOrigin = e.origin === new URL(this.observabilityIframeSrc)?.origin;
      if (!isExpectedOrigin) return;

      const {
        data: { type, payload },
      } = e;
      switch (type) {
        case MESSAGE_EVENT_TYPE.GOUI_LOADED:
          this.$refs.iframeSkeleton.handleSkeleton();
          break;
        case MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE:
          this.routeUpdateHandler(payload);
          break;
        default:
          break;
      }
    },
    routeUpdateHandler(payload) {
      const isNewObservabilityPath = this.$route?.query?.observability_path !== payload?.url;

      const shouldNotHandleMessage = !payload.url || !isNewObservabilityPath;

      if (shouldNotHandleMessage) {
        return;
      }

      // this will update the `observability_path` query param on each route change inside Observability UI
      this.$router.replace({
        name: this.$route.pathname,
        query: { ...this.$route.query, observability_path: payload.url },
      });
    },
  },
};
</script>

<template>
  <observability-skeleton ref="iframeSkeleton" :variant="getSkeletonVariant">
    <iframe
      id="observability-ui-iframe"
      data-testid="observability-ui-iframe"
      frameborder="0"
      height="100%"
      :src="iframeSrcWithParams"
      sandbox="allow-same-origin allow-forms allow-scripts"
    ></iframe>
  </observability-skeleton>
</template>
