<script>
import { GlDrawer, GlButton } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_CONTAINER_CLASS, i18n } from './constants';

export default {
  i18n,
  components: {
    GlDrawer,
    GlButton,
  },
  props: {
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    zIndex: {
      type: Number,
      required: false,
      default: 200,
    },
  },
  computed: {
    drawerHeightOffset() {
      return getContentWrapperHeight(DRAWER_CONTAINER_CLASS);
    },
  },
  methods: {
    closeDrawer() {
      this.$emit('close-job-assistant-drawer');
    },
  },
};
</script>
<template>
  <gl-drawer
    class="job-assistant-drawer"
    :header-height="drawerHeightOffset"
    :open="isVisible"
    :z-index="zIndex"
    @close="closeDrawer"
  >
    <template #title>
      <h2 class="gl-m-0 gl-font-lg">{{ $options.i18n.ADD_JOB }}</h2>
    </template>
    <template #footer>
      <div class="gl-display-flex gl-justify-content-end">
        <gl-button
          category="primary"
          class="gl-mr-3"
          data-testid="cancel-button"
          @click="closeDrawer"
          >{{ __('Cancel') }}</gl-button
        >
        <gl-button category="primary" variant="confirm" data-testid="confirm-button">{{
          __('Add')
        }}</gl-button>
      </div>
    </template>
  </gl-drawer>
</template>
