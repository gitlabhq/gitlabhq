<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: { GlButton, LocalStorageSync },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['isIconOnly'],
  computed: {
    icon() {
      return 'sidebar';
    },
    text() {
      return this.isIconOnly
        ? s__('Navigation|Expand sidebar')
        : s__('Navigation|Collapse sidebar');
    },
  },
  methods: {
    emitToggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <local-storage-sync
    storage-key="super-sidebar-is-icon-only"
    :value="isIconOnly"
    @input="emitToggle"
  >
    <gl-button
      v-gl-tooltip.right="isIconOnly ? text : ''"
      :class="['gl-mx-2 gl-my-2 !gl-justify-start gl-font-semibold', { 'gl-gap-3': !isIconOnly }]"
      :icon="icon"
      category="tertiary"
      @click="emitToggle"
      >{{ isIconOnly ? '' : text }}</gl-button
    >
  </local-storage-sync>
</template>
