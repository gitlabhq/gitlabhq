<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';

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
    collapsible: {
      type: Boolean,
      default: true,
      required: false,
    },
  },
  data() {
    const forceOpen = !this.collapsible || this.defaultExpanded;
    return {
      // Non-collapsible sections should always be expanded.
      // For collapsible sections, fall back to defaultExpanded.
      sectionExpanded: forceOpen,
      initialised: forceOpen,
      animating: false,
    };
  },
  computed: {
    toggleText() {
      const { collapseText, expandText } = this.$options.i18n;
      return this.sectionExpanded ? collapseText : expandText;
    },
    settingsContentId() {
      return uniqueId('settings_content_');
    },
    settingsLabelId() {
      return uniqueId('settings_label_');
    },
    toggleButtonAriaLabel() {
      const { collapseAriaLabel, expandAriaLabel } = this.$options.i18n;
      return this.sectionExpanded ? collapseAriaLabel : expandAriaLabel;
    },
    ariaExpanded() {
      return String(this.sectionExpanded);
    },
  },
  methods: {
    toggleSectionExpanded() {
      this.sectionExpanded = !this.sectionExpanded;

      if (!this.initialised) {
        this.initialised = true;
      }

      if (this.sectionExpanded) {
        this.animating = true;
        this.$refs.settingsContent.focus();
      }
    },
  },
  i18n: {
    collapseText: __('Collapse'),
    expandText: __('Expand'),
    collapseAriaLabel: __('Collapse settings section'),
    expandAriaLabel: __('Expand settings section'),
  },
};
</script>

<template>
  <section
    class="settings"
    :class="{ 'no-animate': !slideAnimated, expanded: sectionExpanded, animating }"
  >
    <div class="settings-header">
      <h4>
        <span
          v-if="collapsible"
          :id="settingsLabelId"
          role="button"
          tabindex="0"
          class="gl-cursor-pointer"
          :aria-controls="settingsContentId"
          :aria-expanded="ariaExpanded"
          data-testid="section-title-button"
          @click="toggleSectionExpanded"
          @keydown.enter.space="toggleSectionExpanded"
        >
          <slot name="title"></slot>
        </span>
        <template v-else>
          <slot name="title"></slot>
        </template>
      </h4>
      <gl-button
        v-if="collapsible"
        :aria-controls="settingsContentId"
        :aria-expanded="ariaExpanded"
        :aria-label="toggleButtonAriaLabel"
        @click="toggleSectionExpanded"
      >
        {{ toggleText }}
      </gl-button>
      <p>
        <slot name="description"></slot>
      </p>
    </div>
    <div
      v-show="initialised"
      :id="settingsContentId"
      ref="settingsContent"
      :aria-labelledby="settingsLabelId"
      tabindex="-1"
      role="region"
      class="settings-content"
      @animationend="animating = false"
    >
      <slot></slot>
    </div>
  </section>
</template>
