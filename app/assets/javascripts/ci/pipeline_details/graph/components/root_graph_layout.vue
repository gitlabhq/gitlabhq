<script>
import { GlCard } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'RootGraphLayout',
  components: {
    GlCard,
  },
  mixins: [glSlotsMixin],
};
</script>
<template>
  <div>
    <gl-card class="ci-card" header-class="gl-px-0 gl-pb-4" body-class="gl-pt-2 gl-pb-0 gl-px-0">
      <template v-if="glSlots().stages" #header>
        <slot name="stages"></slot>
      </template>

      <slot name="jobs"></slot>
    </gl-card>
  </div>
</template>
