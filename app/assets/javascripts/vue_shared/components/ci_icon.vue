<script>
  import { statusIconEntityMap, statusCssClasses } from '../../vue_shared/ci_status_icons';

  export default {
    props: {
      status: {
        type: Object,
        required: true,
      },
    },

    computed: {
      statusIconSvg() {
        return statusIconEntityMap[this.status.icon];
      },

      cssClass() {
        const status = statusCssClasses[this.status.icon];
        return `ci-status-icon ci-status-icon-${status} js-ci-status-icon-${status}`;
      },
    },
  };
</script>
<template>
  <span
    :class="cssClass"
    v-html="statusIconSvg">
  </span>
</template>
