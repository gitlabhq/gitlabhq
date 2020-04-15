<script>
import { GlNewButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlNewButton,
    GlLoadingIcon,
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
  <div class="d-flex bg-light border-top justify-content-between align-items-center py-3 px-4">
    <gl-loading-icon :class="{ invisible: !savingChanges }" size="md" />
    <div>
      <gl-new-button v-if="returnUrl" ref="returnUrlLink" :href="returnUrl">{{
        s__('StaticSiteEditor|Return to site')
      }}</gl-new-button>
      <gl-new-button
        variant="success"
        :disabled="!saveable || savingChanges"
        @click="$emit('submit')"
      >
        {{ __('Submit Changes') }}
      </gl-new-button>
    </div>
  </div>
</template>
