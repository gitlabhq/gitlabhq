<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import ciIcon from '../../vue_shared/components/ci_icon.vue';

export default {
  components: {
    ciIcon,
    GlButton,
    GlLoadingIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    showDisabledButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isLoading() {
      return this.status === 'loading';
    },
    statusObj() {
      return {
        group: this.status,
        icon: `status_${this.status}`,
      };
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-self-start">
    <div class="square s24 h-auto d-flex-center gl-mr-3">
      <div v-if="isLoading" class="mr-widget-icon gl-display-inline-flex">
        <gl-loading-icon size="md" class="mr-loading-icon gl-display-inline-flex" />
      </div>
      <ci-icon v-else :status="statusObj" :size="24" />
    </div>

    <gl-button
      v-if="showDisabledButton"
      category="primary"
      variant="success"
      data-testid="disabled-merge-button"
      :disabled="true"
    >
      {{ s__('mrWidget|Merge') }}
    </gl-button>
  </div>
</template>
