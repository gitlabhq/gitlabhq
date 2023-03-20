<script>
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { setUrlParams } from '~/lib/utils/url_utility';

import { MESSAGE_EVENT_TYPE, FULL_APP_DIMENSIONS } from '../constants';
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
    inlineEmbed: {
      type: Boolean,
      required: false,
      default: false,
    },
    skeletonVariant: {
      type: String,
      required: false,
      default: 'dashboards',
    },
    height: {
      type: String,
      required: false,
      default: FULL_APP_DIMENSIONS.HEIGHT,
    },
    width: {
      type: String,
      required: false,
      default: FULL_APP_DIMENSIONS.WIDTH,
    },
  },
  computed: {
    iframeSrcWithParams() {
      return `${setUrlParams(
        { theme: darkModeEnabled() ? 'dark' : 'light', username: gon?.current_username },
        this.observabilityIframeSrc,
      )}${this.inlineEmbed ? '&kiosk=inline-embed' : ''}`;
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
          this.$refs.observabilitySkeleton.onContentLoaded();
          break;
        case MESSAGE_EVENT_TYPE.GOUI_ROUTE_UPDATE:
          this.$emit('route-update', payload);
          break;
        default:
          break;
      }
    },
  },
};
</script>

<template>
  <observability-skeleton ref="observabilitySkeleton" :variant="skeletonVariant">
    <iframe
      id="observability-ui-iframe"
      data-testid="observability-ui-iframe"
      frameborder="0"
      :width="width"
      :height="height"
      :src="iframeSrcWithParams"
      sandbox="allow-same-origin allow-forms allow-scripts"
    ></iframe>
  </observability-skeleton>
</template>
