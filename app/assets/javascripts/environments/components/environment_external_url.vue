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
  computed: {
    title() {
      return s__('Environments|Open live environment');
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    :title="title"
    :aria-label="title"
    :href="externalUrl"
    class="external-url"
    target="_blank"
    icon="external-link"
    rel="noopener noreferrer nofollow"
  />
</template>
