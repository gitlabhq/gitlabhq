<script>
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  components: {
    TooltipOnTruncate,
  },
  props: {
    stageName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <tooltip-on-truncate :title="stageName" truncate-target="child" placement="top">
    <h2 class="gl-m-0 gl-w-20 gl-truncate gl-py-2 gl-text-base gl-font-bold gl-leading-normal">
      {{ stageName }}
    </h2>
  </tooltip-on-truncate>
</template>
