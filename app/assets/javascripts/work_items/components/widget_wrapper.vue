<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  props: {
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isOpen: true,
    };
  },
  computed: {
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? __('Collapse') : __('Expand');
    },
  },
  methods: {
    hide() {
      this.isOpen = false;
    },
    show() {
      this.isOpen = true;
    },
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
};
</script>

<template>
  <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-bg-gray-10 gl-mt-4">
    <div
      class="gl-rounded-top-left-base gl-rounded-top-right-base gl-pl-5 gl-pr-4 gl-py-4 gl-display-flex gl-justify-content-space-between gl-bg-white"
      :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': isOpen }"
    >
      <div class="gl-display-flex gl-flex-grow-1">
        <h5 class="gl-m-0 gl-line-height-24">
          <slot name="header"></slot>
        </h5>
        <slot name="header-suffix"></slot>
      </div>
      <slot name="header-right"></slot>
      <div class="gl-border-l-1 gl-border-l-solid gl-border-l-gray-100 gl-pl-3 gl-ml-3">
        <gl-button
          category="tertiary"
          size="small"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="widget-toggle"
          @click="toggle"
        />
      </div>
    </div>
    <gl-alert v-if="error" variant="danger" @dismiss="$emit('dismissAlert')">
      {{ error }}
    </gl-alert>
    <div
      v-if="isOpen"
      class="gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
      :class="{ 'gl-p-5 gl-pb-3': !error }"
      data-testid="widget-body"
    >
      <slot name="body"></slot>
    </div>
  </div>
</template>
