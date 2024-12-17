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
    isExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isVisible: this.isExpanded,
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
  <li class="gl-border-b-2 gl-border-b-default gl-py-3 gl-leading-20 gl-border-b-solid">
    <div
      :class="{
        'gl-flex gl-flex-wrap gl-items-center gl-justify-between': collapsible,
      }"
    >
      <slot name="label">
        <label class="gl-mb-0 gl-font-bold"> {{ label }} </label>
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

    <div v-else class="gl-mb-0 gl-mt-2 gl-text-subtle">
      <slot></slot>
    </div>
  </li>
</template>
