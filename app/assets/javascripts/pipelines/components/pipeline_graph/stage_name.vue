<script>
import { capitalize, escape } from 'lodash';
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
  },
  computed: {
    formattedTitle() {
      return capitalize(escape(this.stageName));
    },
  },
};
</script>
<template>
  <tooltip-on-truncate :title="stageName" truncate-target="child" placement="top">
    <div class="gl-py-2 gl-text-truncate gl-font-weight-bold gl-w-20">
      {{ formattedTitle }}
    </div>
  </tooltip-on-truncate>
</template>
