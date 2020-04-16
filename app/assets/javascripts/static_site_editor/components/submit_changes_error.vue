<script>
import { GlAlert, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  props: {
    error: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <gl-alert variant="danger" dismissible @dismiss="$emit('dismiss')">
    {{ s__('StaticSiteEditor|An error occurred while submitting your changes.') }} {{ error }}
    <template #actions>
      <gl-button variant="danger" @click="$emit('retry')">{{ __('Retry') }}</gl-button>
    </template>
  </gl-alert>
</template>
