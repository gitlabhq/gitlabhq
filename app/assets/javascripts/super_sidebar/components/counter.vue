<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon } from '@gitlab/ui';
import { highCountTrim } from '~/lib/utils/text_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlIcon,
  },
  mixins: [glFeatureFlagsMixin()],
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
    superTopbarEnabled() {
      return this.glFeatures.globalTopbar;
    },
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
    class="dashboard-shortcuts-button gl-relative gl-flex gl-items-center gl-justify-center"
  >
    <gl-icon
      aria-hidden="true"
      :name="icon"
      class="gl-shrink-0"
      :class="{
        '!gl-mr-0': superTopbarEnabled,
        'notification-dot-mask': count && superTopbarEnabled,
      }"
    />
    <span v-if="count && superTopbarEnabled" class="notification-dot"></span>
    <span v-else-if="count" aria-hidden="true" class="gl-font-semibold">{{ formattedCount }}</span>
  </component>
</template>
