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
  <span class="gl-flex gl-items-center">
    <ci-icon
      :size="iconSize"
      :status="status"
      :show-tooltip="false"
      :use-link="false"
      class="gl-leading-0"
    />
    <span class="gl-line-clamp-2 gl-pl-3 gl-wrap-anywhere" :title="name">
      {{ name }}
    </span>
  </span>
</template>
