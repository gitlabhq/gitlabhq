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
      return this.isIconOnly ? 'expand-left' : 'collapse-left';
    },
    text() {
      return this.isIconOnly ? s__('Navigation|Expand sidebar') : s__('Navigation|Shrink sidebar');
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
      class="gl-mx-3 gl-my-2"
      :icon="icon"
      size="small"
      category="tertiary"
      button-text-classes="gl-text-sm"
      @click="emitToggle"
      >{{ isIconOnly ? '' : text }}</gl-button
    >
  </local-storage-sync>
</template>
