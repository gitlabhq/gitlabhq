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
    widgetName: {
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
    anchorLink() {
      return `#${this.widgetName}`;
    },
    anchorLinkId() {
      return `user-content-${this.widgetName}-links`;
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
    :id="widgetName"
    data-testid="widget-wrapper"
    class="gl-new-card"
    :class="{ 'is-collapsed': !isOpen }"
  >
    <div class="gl-new-card-header">
      <div class="gl-new-card-title-wrapper">
        <h2 class="gl-new-card-title">
          <div aria-hidden="true">
            <gl-link
              :id="anchorLinkId"
              class="gl-text-decoration-none gl-hidden"
              :href="anchorLink"
            />
          </div>
          <slot name="header"></slot>
        </h2>
        <slot name="header-suffix"></slot>
      </div>
      <slot name="header-right"></slot>
      <div class="gl-new-card-toggle">
        <!-- https://www.w3.org/TR/wai-aria-1.2/#aria-expanded -->
        <gl-button
          category="tertiary"
          size="small"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="widget-toggle"
          :aria-expanded="isOpenString"
          :aria-controls="widgetName"
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
