<script>
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

  computed: {
    title() {
      return 'Open';
    },
  },

  destroyed() {
    $(this.$el).tooltip('destroy');
  },
};
</script>
<template>
  <a
    class="btn external-url has-tooltip"
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
