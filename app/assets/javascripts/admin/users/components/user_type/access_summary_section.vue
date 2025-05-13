<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: { GlIcon },
  props: {
    icon: {
      type: String,
      required: true,
    },
    headerText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <section>
    <gl-icon :name="icon" /> <span>{{ headerText }}</span>
    <ul v-if="$scopedSlots.list" class="gl-mb-0 gl-ml-2 gl-pl-7 gl-text-subtle">
      <slot name="list"></slot>
    </ul>
    <div v-if="$scopedSlots.default" class="gl-pl-5 gl-text-subtle">
      <slot></slot>
    </div>
  </section>
</template>
