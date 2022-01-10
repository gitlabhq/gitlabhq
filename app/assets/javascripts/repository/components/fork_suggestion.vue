<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    message: __(
      'You can’t edit files directly in this project. Fork this project and submit a merge request with your changes.',
    ),
    fork: __('Fork'),
    cancel: __('Cancel'),
  },
  components: {
    GlButton,
  },
  props: {
    forkPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-end gl-align-items-center gl-bg-gray-10 gl-px-5 gl-py-2 gl-border-1 gl-border-b-solid gl-border-gray-100"
  >
    <span class="gl-mr-6" data-testid="message">{{ $options.i18n.message }}</span>

    <gl-button
      class="gl-mr-3"
      category="secondary"
      variant="confirm"
      data-method="post"
      :href="forkPath"
      data-testid="fork"
    >
      {{ $options.i18n.fork }}
    </gl-button>

    <gl-button data-testid="cancel" @click="$emit('cancel')">
      {{ $options.i18n.cancel }}
    </gl-button>
  </div>
</template>
