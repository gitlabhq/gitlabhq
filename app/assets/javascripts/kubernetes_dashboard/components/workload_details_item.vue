<script>
import { GlCollapse, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlCollapse,
    GlButton,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    collapsible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isVisible: false,
    };
  },
  computed: {
    chevronIcon() {
      return this.isVisible ? 'chevron-down' : 'chevron-right';
    },
    collapsibleLabel() {
      return this.isVisible ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
  },
  methods: {
    toggleCollapse() {
      this.isVisible = !this.isVisible;
    },
  },
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
  },
};
</script>

<template>
  <li class="gl-leading-20 gl-py-3 gl-border-b-solid gl-border-b-2 gl-border-b-gray-100">
    <div
      :class="{
        'gl-display-flex gl-flex-wrap gl-justify-content-space-between gl-align-items-center':
          collapsible,
      }"
    >
      <slot name="label">
        <label class="gl-font-bold gl-mb-0"> {{ label }} </label>
      </slot>

      <gl-button
        v-if="collapsible"
        :icon="chevronIcon"
        :aria-label="collapsibleLabel"
        category="tertiary"
        size="small"
        class="gl-ml-auto"
        @click="toggleCollapse"
      />
    </div>

    <gl-collapse v-if="collapsible" :visible="isVisible">
      <div v-if="isVisible" class="gl-mt-4">
        <slot></slot>
      </div>
    </gl-collapse>

    <div v-else class="gl-text-gray-500 gl-mb-0 gl-mt-2">
      <slot></slot>
    </div>
  </li>
</template>
