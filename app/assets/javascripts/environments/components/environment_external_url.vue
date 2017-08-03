<script>
import tooltip from '../../vue_shared/directives/tooltip';

/**
 * Renders the external url link in environments table.
 */
export default {
  props: {
    externalUrl: {
      type: String,
      required: true,
    },
  },

  directives: {
    tooltip,
  },

  computed: {
    title() {
      return 'Open';
    },
  },
};
</script>
<template>
  <a
    v-tooltip
    class="btn external-url"
    data-container="body"
    target="_blank"
    rel="noopener noreferrer nofollow"
    :title="title"
    :aria-label="title"
    :href="externalUrl">
    <i
      class="fa fa-external-link"
      aria-hidden="true" />
  </a>
</template>
