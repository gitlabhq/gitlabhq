<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    edit: __('Edit'),
    webIde: __('Web IDE'),
  },
  components: {
    GlButton,
  },
  props: {
    editPath: {
      type: String,
      required: true,
    },
    webIdePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <gl-button class="gl-mr-2" category="primary" variant="confirm" :href="editPath">
      {{ $options.i18n.edit }}
    </gl-button>

    <gl-button class="gl-mr-3" category="primary" variant="confirm" :href="webIdePath">
      {{ $options.i18n.webIde }}
    </gl-button>
  </div>
</template>
