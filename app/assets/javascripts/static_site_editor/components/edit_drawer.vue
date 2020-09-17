<script>
import { GlDrawer } from '@gitlab/ui';
import FrontMatterControls from './front_matter_controls.vue';

export default {
  components: {
    GlDrawer,
    FrontMatterControls,
  },
  props: {
    isOpen: {
      type: Boolean,
      required: true,
    },
    settings: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <gl-drawer class="gl-pt-8" :open="isOpen" @close="$emit('close')">
    <template #header>{{ __('Page settings') }}</template>
    <template>
      <front-matter-controls
        :settings="settings"
        @updateSettings="$emit('updateSettings', $event)"
      />
    </template>
  </gl-drawer>
</template>
