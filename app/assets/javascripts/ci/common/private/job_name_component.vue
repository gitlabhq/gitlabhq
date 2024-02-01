<script>
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

/**
 * Component that renders both the CI icon status and the job name.
 * Used in
 *  - Badge component
 *  - Dropdown badge components
 */
export default {
  components: {
    CiIcon,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    status: {
      type: Object,
      required: true,
    },
    iconSize: {
      type: Number,
      required: false,
      default: 16,
    },
  },
};
</script>
<template>
  <span class="gl-max-w-full gl-display-flex gl-align-items-center gl-flex-grow-1">
    <ci-icon
      :size="iconSize"
      :status="status"
      :show-tooltip="false"
      :use-link="false"
      class="gl-line-height-0"
    />
    <span class="gl-text-truncate mw-70p gl-pl-3 gl-display-inline-block">
      {{ name }}
    </span>
  </span>
</template>
