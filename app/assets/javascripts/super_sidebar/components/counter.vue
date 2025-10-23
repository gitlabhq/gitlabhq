<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import { highCountTrim } from '~/lib/utils/text_utility';

export default {
  components: {
    GlIcon,
  },
  props: {
    count: {
      type: [Number, String],
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
  },
  computed: {
    ariaLabel() {
      return `${this.count} ${this.label}`;
    },
    component() {
      return this.href ? 'a' : 'button';
    },
    formattedCount() {
      if (Number.isFinite(this.count)) {
        return highCountTrim(this.count);
      }
      return this.count;
    },
    countExists() {
      return this.count.toString();
    },
  },
};
</script>

<template>
  <component
    :is="component"
    :aria-label="ariaLabel"
    :href="href"
    class="dashboard-shortcuts-button gl-relative gl-flex gl-items-center gl-justify-center"
  >
    <gl-icon aria-hidden="true" :name="icon" class="gl-shrink-0" />
    <span v-if="countExists" aria-hidden="true" class="gl-text-sm gl-font-semibold">{{
      formattedCount
    }}</span>
  </component>
</template>
