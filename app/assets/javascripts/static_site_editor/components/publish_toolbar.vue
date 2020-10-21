<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    hasSettings: {
      type: Boolean,
      required: false,
      default: false,
    },
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
        v-if="hasSettings"
        ref="settings"
        :disabled="savingChanges"
        @click="$emit('editSettings')"
      >
        {{ __('Page settings') }}
      </gl-button>
      <gl-button
        ref="submit"
        variant="success"
        :disabled="!saveable"
        :loading="savingChanges"
        @click="$emit('submit')"
      >
        {{ __('Submit changes...') }}
      </gl-button>
    </div>
  </div>
</template>
