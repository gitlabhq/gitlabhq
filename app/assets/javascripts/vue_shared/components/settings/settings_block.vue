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
    <div class="gl-flex gl-items-start gl-justify-between">
      <div class="gl-grow">
        <h2
          role="button"
          tabindex="-1"
          class="gl-heading-2 !gl-mb-2 gl-cursor-pointer"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          @click="toggleExpanded"
        >
          <slot v-if="$scopedSlots.title" name="title"></slot>
          <template v-else>{{ title }}</template>
        </h2>
        <p class="gl-m-0 gl-text-subtle"><slot name="description"></slot></p>
      </div>
      <div class="gl-shrink-0 gl-px-2">
        <gl-button
          class="gl-min-w-12 gl-shrink-0"
          :aria-expanded="ariaExpanded"
          :aria-controls="collapseId"
          @click="toggleExpanded"
        >
          <span aria-hidden="true">
            {{ toggleButtonText }}
          </span>
          <span class="gl-sr-only">
            {{ toggleButtonText }}
            <slot v-if="$scopedSlots.title" name="title"></slot>
            <template v-else>{{ title }}</template>
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
