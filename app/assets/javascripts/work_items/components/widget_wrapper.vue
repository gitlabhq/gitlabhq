<script>
import { GlAlert, GlButton, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLink,
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
  <div
    id="tasks"
    class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-bg-gray-10 gl-mt-5"
  >
    <div
      class="gl-pl-5 gl-pr-4 gl-py-4 gl-display-flex gl-justify-content-space-between gl-bg-white gl-rounded-base"
      :class="{
        'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100 gl-rounded-bottom-left-none! gl-rounded-bottom-right-none!': isOpen,
      }"
    >
      <div class="gl-display-flex gl-flex-grow-1">
        <h3 class="card-title h5 gl-m-0 gl-relative gl-line-height-24">
          <gl-link
            id="user-content-tasks-links"
            class="anchor position-absolute gl-text-decoration-none"
            href="#tasks"
            aria-hidden="true"
          />
          <slot name="header"></slot>
        </h3>
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
      :class="{ 'gl-p-3': !error }"
      data-testid="widget-body"
    >
      <slot name="body"></slot>
    </div>
  </div>
</template>
