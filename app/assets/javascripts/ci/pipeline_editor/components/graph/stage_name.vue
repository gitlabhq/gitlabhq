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
    <div class="gl-w-20 gl-truncate gl-py-2 gl-font-bold">
      {{ stageName }}
    </div>
  </tooltip-on-truncate>
</template>
