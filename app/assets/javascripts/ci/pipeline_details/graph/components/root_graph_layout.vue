<script>
import { GlCard } from '@gitlab/ui';

export default {
  name: 'RootGraphLayout',
  components: {
    GlCard,
  },
};
</script>
<template>
  <div>
    <gl-card class="ci-card" header-class="gl-px-0 gl-pb-4" body-class="gl-pt-2 gl-pb-0 gl-px-0">
      <template v-if="$scopedSlots.stages" #header>
        <slot name="stages"></slot>
      </template>

      <slot name="jobs"></slot>
    </gl-card>
  </div>
</template>
