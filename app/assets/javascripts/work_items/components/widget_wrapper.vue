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
    isOpenString() {
      return this.isOpen ? 'true' : 'false';
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
  <div id="tasks" class="gl-new-card" :aria-expanded="isOpenString">
    <div class="gl-new-card-header">
      <div class="gl-new-card-title-wrapper">
        <h3 class="gl-new-card-title">
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
      <div class="gl-new-card-toggle">
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
    <div v-if="isOpen" class="gl-new-card-body" :class="{ error: error }" data-testid="widget-body">
      <slot name="body"></slot>
    </div>
  </div>
</template>
