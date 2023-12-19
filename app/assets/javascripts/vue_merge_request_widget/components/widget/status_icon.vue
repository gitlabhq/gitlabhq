<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { EXTENSION_ICON_CLASS, EXTENSION_ICON_NAMES } from '../../constants';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    level: {
      type: Number,
      required: false,
      default: 1,
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    iconName: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    iconAriaLabel() {
      return `${capitalizeFirstCharacter(this.iconName)} ${this.name}`;
    },
    iconClassNameText() {
      return this.$options.EXTENSION_ICON_CLASS[this.iconName];
    },
  },
  EXTENSION_ICON_NAMES,
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <div
    :class="{
      [iconClassNameText]: !isLoading,
      [`mr-widget-status-icon-level-${level}`]: !isLoading,
      'gl-w-6 gl-h-6 gl--flex-center': level === 1,
    }"
    class="gl-relative gl-rounded-full gl-mr-3"
  >
    <gl-loading-icon v-if="isLoading" size="sm" inline />
    <gl-icon
      v-else
      :name="$options.EXTENSION_ICON_NAMES[iconName]"
      :size="12"
      :aria-label="iconAriaLabel"
      :data-testid="`status-${iconName}-icon`"
      class="gl-relative gl-z-index-1"
    />
  </div>
</template>
