<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

/**
 * Renders the external url link in environments table.
 */
export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    externalUrl: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: s__('Environments|Open live environment'),
    open: s__('Environments|Open'),
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    :title="$options.i18n.title"
    :aria-label="$options.i18n.title"
    :href="externalUrl"
    is-unsafe-link
    size="small"
    class="external-url"
    target="_blank"
    icon="external-link"
    rel="noopener noreferrer nofollow"
  >
    {{ $options.i18n.open }}
  </gl-button>
</template>
