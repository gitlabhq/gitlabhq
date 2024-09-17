<script>
import { GlButton, GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlModal,
  },
  props: {
    currentRequest: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isInfoModalShown: false,
    };
  },
  computed: {
    host() {
      return this.currentRequest?.details?.host;
    },
    hostInfo() {
      return this.host?.hostname || s__('PerformanceBar|There is no host information');
    },
    isCanary() {
      return Boolean(this.host?.canary);
    },
  },
  methods: {
    showInfoModal() {
      this.isInfoModalShown = true;
    },
  },
};
</script>
<template>
  <div class="view gl-flex gl-gap-2">
    <gl-button
      icon="information-o"
      variant="link"
      :aria-label="s__('PerformanceBar|Debugging information')"
      @click="showInfoModal"
    />
    <gl-modal
      v-model="isInfoModalShown"
      modal-id="environment-info"
      :title="s__('PerformanceBar|Debugging information')"
      size="sm"
      hide-backdrop
      hide-footer
    >
      <div class="gl-pb-6">
        <div class="gl-flex gl-flex-col gl-text-lg">
          <strong class="gl-border-b gl-mb-4 gl-w-full gl-font-bold">
            {{ s__('PerformanceBar|Host') }}</strong
          >
          <div>
            <gl-emoji data-testid="host-emoji" data-name="computer" />
            <span>{{ hostInfo }} </span>
          </div>
          <div v-if="isCanary">
            <gl-emoji data-testid="canary-emoji" data-name="baby_chick" />
            <span>{{ s__('PerformanceBar|Request made from Canary') }}</span>
          </div>
        </div>
      </div>
    </gl-modal>
  </div>
</template>
