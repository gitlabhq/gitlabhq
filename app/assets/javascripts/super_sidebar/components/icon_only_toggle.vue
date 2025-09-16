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
      :class="[
        'super-sidebar-nav-item !gl-mx-3 !-gl-mt-2 !gl-mb-2 !gl-justify-start !gl-px-[0.375rem] !gl-py-2 gl-font-semibold',
        { 'gl-gap-3': !isIconOnly },
      ]"
      :button-text-classes="isIconOnly ? 'gl-hidden' : null"
      :icon="icon"
      category="tertiary"
      @click="emitToggle"
      >{{ text }}</gl-button
    >
  </local-storage-sync>
</template>
