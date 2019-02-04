<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { s__ } from '~/locale';

/**
 * Renders the external url link in environments table.
 */
export default {
  components: {
    Icon,
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
  <a
    v-gl-tooltip
    :title="title"
    :aria-label="title"
    :href="externalUrl"
    class="btn external-url"
    target="_blank"
    rel="noopener noreferrer nofollow"
  >
    <icon name="external-link" />
  </a>
</template>
