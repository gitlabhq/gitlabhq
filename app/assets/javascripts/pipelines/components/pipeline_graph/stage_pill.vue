<script>
import tooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  components: {
    tooltipOnTruncate,
  },
  props: {
    stageName: {
      type: String,
      required: true,
    },
    isEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    emptyClass() {
      return this.isEmpty ? 'gl-bg-gray-200' : 'gl-bg-gray-600';
    },
  },
};
</script>
<template>
  <tooltip-on-truncate :title="stageName" truncate-target="child" placement="top">
    <div
      class="gl-px-5 gl-py-2 gl-text-white gl-text-center gl-text-truncate gl-rounded-pill gl-w-20"
      :class="emptyClass"
    >
      {{ stageName }}
    </div>
  </tooltip-on-truncate>
</template>
