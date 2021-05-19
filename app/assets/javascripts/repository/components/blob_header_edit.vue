<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    edit: __('Edit'),
  },
  components: {
    GlButton,
  },
  props: {
    editPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-button category="primary" variant="confirm" class="gl-mr-3" :href="editPath">
    {{ $options.i18n.edit }}
  </gl-button>
</template>
