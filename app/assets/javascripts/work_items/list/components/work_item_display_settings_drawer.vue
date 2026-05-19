<script>
import { GlDrawer } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

export default {
  name: 'WorkItemDisplaySettingsDrawer',
  components: {
    GlDrawer,
  },
  i18n: {
    title: s__('WorkItems|Display'),
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['close'],
  computed: {
    drawerHeaderHeight() {
      return getContentWrapperHeight();
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :header-height="drawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    data-testid="display-settings-drawer"
    @close="onClose"
  >
    <template #title>
      <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">{{ $options.i18n.title }}</h2>
    </template>
    <template #default>
      <slot></slot>
    </template>
  </gl-drawer>
</template>
