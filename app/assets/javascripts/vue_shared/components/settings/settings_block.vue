<script>
import { GlButton, GlCollapse } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import { __ } from '~/locale';

export default {
  components: { GlButton, GlCollapse },
  props: {
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
  <section class="vue-settings-block">
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-flex-start">
      <div class="gl-flex-grow-1">
        <h4
          role="button"
          tabindex="-1"
          class="gl-cursor-pointer gl-mt-0 gl-mb-3"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          @click="toggleExpanded"
        >
          <slot name="title"></slot>
        </h4>
        <p class="gl-text-secondary gl-m-0"><slot name="description"></slot></p>
      </div>
      <div class="gl-flex-shrink-0 gl-px-3">
        <gl-button
          class="gl-min-w-12"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          @click="toggleExpanded"
        >
          <span aria-hidden="true">
            {{ toggleButtonText }}
          </span>
          <span class="gl-sr-only">
            {{ toggleButtonText }}
            <slot name="title"></slot>
          </span>
        </gl-button>
      </div>
    </div>
    <gl-collapse :id="collapseId" v-model="expanded">
      <div class="gl-pt-5">
        <slot></slot>
      </div>
    </gl-collapse>
  </section>
</template>
