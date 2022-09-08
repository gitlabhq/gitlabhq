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
    <div class="gl-py-2 gl-text-truncate gl-font-weight-bold gl-w-20">
      {{ stageName }}
    </div>
  </tooltip-on-truncate>
</template>
