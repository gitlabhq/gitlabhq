<script>
  import tooltip from '../../vue_shared/directives/tooltip';
  import { s__ } from '../../locale';

  /**
  * Renders the external url link in environments table.
  */
  export default {
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
    <i
      class="fa fa-external-link"
      aria-hidden="true"
    >
    </i>
  </a>
</template>
