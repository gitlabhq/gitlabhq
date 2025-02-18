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
    class="gl-flex gl-items-center gl-justify-end gl-border-1 gl-border-default gl-bg-subtle gl-px-5 gl-py-2 gl-border-b-solid"
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
