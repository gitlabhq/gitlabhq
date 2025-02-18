<script>
import { GlButton, GlCollapse } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import { __ } from '~/locale';

export default {
  components: { GlButton, GlCollapse },
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
    defaultExpanded: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      expanded: window.location.hash?.replace('#', '') === this.id || this.defaultExpanded,
    };
  },
  computed: {
    ariaExpanded() {
      return this.expanded ? 'true' : 'false';
    },
    toggleButtonText() {
      return this.expanded ? this.$options.i18n.collapseText : this.$options.i18n.expandText;
    },
    toggleButtonAriaLabel() {
      return `${this.toggleButtonText} ${this.$scopedSlots.title || this.title}`;
    },
    expandedClass() {
      return this.expanded ? 'expanded' : '';
    },
    collapseId() {
      return this.id || uniqueId('settings-block-');
    },
  },
  methods: {
    toggleExpanded() {
      this.expanded = !this.expanded;
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
      <div class="-gl-mr-3 gl-shrink-0 gl-px-2 gl-py-0 sm:gl-mr-0 sm:gl-p-2">
        <gl-button
          category="tertiary"
          size="small"
          class="settings-toggle gl-shrink-0 !gl-pl-2 !gl-pr-0"
          icon="chevron-lg-right"
          button-text-classes="gl-sr-only"
          :aria-label="toggleButtonAriaLabel"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          data-testid="settings-block-toggle"
          @click="toggleExpanded"
        >
          {{ toggleButtonText }}
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
          <h2 class="gl-heading-2 !gl-mb-2" data-event-tracking="settings-block-title">
            {{ title }}
          </h2>
        </button>
        <p class="gl-m-0 gl-text-subtle"><slot name="description"></slot></p>
      </div>
    </div>
    <gl-collapse :id="collapseId" v-model="expanded" data-testid="settings-block-content">
      <div class="gl-pl-7 gl-pt-5 sm:gl-pl-8">
        <slot></slot>
      </div>
    </gl-collapse>
  </section>
</template>
