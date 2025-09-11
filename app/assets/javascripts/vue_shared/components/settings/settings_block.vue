<script>
import { GlButton, GlCollapse, GlAnimatedChevronLgRightDownIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import { __ } from '~/locale';

export default {
  components: { GlButton, GlCollapse, GlAnimatedChevronLgRightDownIcon },
  props: {
    title: {
      type: String,
      required: false,
      default: null,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
    expanded: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      localExpanded: window.location.hash?.replace('#', '') === this.id || this.expanded,
    };
  },

  computed: {
    ariaExpanded() {
      return this.localExpanded ? 'true' : 'false';
    },
    toggleButtonText() {
      return this.localExpanded ? this.$options.i18n.collapseText : this.$options.i18n.expandText;
    },
    toggleButtonAriaLabel() {
      return `${this.toggleButtonText} ${this.$scopedSlots.title || this.title}`;
    },
    expandedClass() {
      return this.localExpanded ? 'expanded' : '';
    },
    collapseId() {
      return this.id || uniqueId('settings-block-');
    },
    isChevronUp() {
      return this.localExpanded;
    },
  },
  watch: {
    expanded(newValue) {
      this.localExpanded = newValue;
    },
  },
  methods: {
    toggleExpanded() {
      this.localExpanded = !this.localExpanded;
      this.$emit('toggle-expand', this.localExpanded);
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
  <section :id="id" class="vue-settings-block settings no-animate" :class="expandedClass">
    <div class="gl-flex gl-items-start gl-justify-between gl-gap-x-3">
      <div class="-gl-mr-3 gl-shrink-0 gl-px-2 gl-py-0 @sm/panel:gl-mr-0 @sm/panel:gl-p-2">
        <gl-button
          category="tertiary"
          size="small"
          class="settings-toggle gl-shrink-0 !gl-px-0 !gl-pl-2"
          :aria-label="toggleButtonAriaLabel"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          data-testid="settings-block-toggle"
          @click="toggleExpanded"
        >
          <gl-animated-chevron-lg-right-down-icon variant="default" :is-on="isChevronUp" />
          <div class="gl-sr-only">{{ toggleButtonText }}</div>
        </gl-button>
      </div>
      <div class="gl-grow">
        <button
          class="gl-w-full gl-border-0 gl-bg-transparent gl-p-0 gl-text-left"
          tabindex="-1"
          type="button"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          data-testid="settings-block-title"
          @click="toggleExpanded"
        >
          <h2 class="gl-heading-2 !gl-mb-2" data-settings-block-title>
            {{ title }}
          </h2>
        </button>
        <p class="gl-m-0 gl-text-subtle"><slot name="description"></slot></p>
      </div>
    </div>
    <gl-collapse :id="collapseId" :visible="localExpanded" data-testid="settings-block-content">
      <div class="gl-pl-7 gl-pt-5 @sm/panel:gl-pl-8">
        <slot></slot>
      </div>
    </gl-collapse>
  </section>
</template>
