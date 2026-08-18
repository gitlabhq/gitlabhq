<script>
import { GlIcon, GlPopover } from '@gitlab/ui';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'StorageTypeWarning',
  components: {
    GlPopover,
    GlIcon,
  },
  mixins: [glSlotsMixin],
  data() {
    return {
      mounted: false,
    };
  },
  mounted() {
    this.mounted = true;
  },
};
</script>

<template>
  <span>
    <gl-icon ref="glIcon" name="warning" class="gl-ml-2" variant="subtle" />
    <gl-popover v-if="mounted" :target="$refs.glIcon" triggers="hover focus" placement="top">
      <template v-if="glSlots().default" #default><slot></slot></template>
    </gl-popover>
  </span>
</template>
