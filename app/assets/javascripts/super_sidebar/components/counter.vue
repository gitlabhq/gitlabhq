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
      return `${this.label} ${this.count}`;
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
  },
};
</script>

<template>
  <component
    :is="component"
    :aria-label="ariaLabel"
    :href="href"
    class="user-bar-button gl-block gl-grow gl-rounded-base gl-py-3 gl-text-center gl-text-sm gl-leading-1 hover:gl-no-underline"
  >
    <gl-icon aria-hidden="true" :name="icon" />
    <span v-if="count" aria-hidden="true" class="gl-ml-1">{{ formattedCount }}</span>
  </component>
</template>
