<script>
  import Icon from '~/vue_shared/components/icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';
  import { s__ } from '../../locale';

  /**
  * Renders the external url link in environments table.
  */
  export default {
    components: {
      Icon,
    },
    directives: {
      tooltip,
    },
    props: {
      externalUrl: {
        type: String,
        required: true,
      },
    },
    computed: {
      title() {
        return s__('Environments|Open');
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
    :href="externalUrl"
  >
    <icon
      name="external-link"
      :size="12"
    />
  </a>
</template>
