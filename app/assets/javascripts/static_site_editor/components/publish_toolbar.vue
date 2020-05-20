<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    returnUrl: {
      type: String,
      required: false,
      default: '',
    },
    saveable: {
      type: Boolean,
      required: false,
      default: false,
    },
    savingChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div class="d-flex bg-light border-top justify-content-end align-items-center py-3 px-4">
    <div>
      <gl-button v-if="returnUrl" ref="returnUrlLink" :href="returnUrl">{{
        s__('StaticSiteEditor|Return to site')
      }}</gl-button>
      <gl-button
        variant="success"
        :disabled="!saveable"
        :loading="savingChanges"
        @click="$emit('submit')"
      >
        <span>{{ __('Submit Changes') }}</span>
      </gl-button>
    </div>
  </div>
</template>
