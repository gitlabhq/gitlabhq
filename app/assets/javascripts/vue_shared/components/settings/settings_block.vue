<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlButton },
  props: {
    slideAnimated: {
      type: Boolean,
      default: true,
      required: false,
    },
    defaultExpanded: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      sectionExpanded: false,
    };
  },
  computed: {
    expanded() {
      return this.defaultExpanded || this.sectionExpanded;
    },
    toggleText() {
      return this.expanded ? __('Collapse') : __('Expand');
    },
  },
  methods: {
    toggleSectionExpanded() {
      this.sectionExpanded = !this.sectionExpanded;
    },
  },
};
</script>

<template>
  <section class="settings" :class="{ 'no-animate': !slideAnimated, expanded }">
    <div class="settings-header">
      <h4>
        <span
          role="button"
          tabindex="0"
          class="gl-cursor-pointer"
          data-testid="section-title"
          @click="toggleSectionExpanded"
        >
          <slot name="title"></slot>
        </span>
      </h4>
      <gl-button @click="toggleSectionExpanded">
        {{ toggleText }}
      </gl-button>
      <p>
        <slot name="description"></slot>
      </p>
    </div>
    <div class="settings-content">
      <slot></slot>
    </div>
  </section>
</template>
