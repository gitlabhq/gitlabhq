<script>
import { GlLoadingIcon } from '@gitlab/ui';
import ciIcon from '../../vue_shared/components/ci_icon.vue';

export default {
  components: {
    ciIcon,
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
  <div class="d-flex align-self-start">
    <div class="square s24 h-auto d-flex-center append-right-default">
      <div v-if="isLoading" class="mr-widget-icon d-inline-flex">
        <gl-loading-icon size="md" class="mr-loading-icon d-inline-flex" />
      </div>
      <ci-icon v-else :status="statusObj" :size="24" />
    </div>

    <button
      v-if="showDisabledButton"
      type="button"
      class="js-disabled-merge-button btn btn-success btn-sm"
      disabled="true"
    >
      {{ s__('mrWidget|Merge') }}
    </button>
  </div>
</template>
