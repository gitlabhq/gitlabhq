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
      default: 0,
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
    size: {
      type: Number,
      required: false,
      default: 12,
    },
  },
  computed: {
    iconAriaLabel() {
      return `${capitalizeFirstCharacter(this.iconName)} ${this.name}`;
    },
  },
  EXTENSION_ICON_NAMES,
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <div
    :class="[
      $options.EXTENSION_ICON_CLASS[iconName],
      { 'mr-widget-extension-icon gl-w-6': !isLoading && level === 1 },
      { 'gl-p-2': isLoading || level === 1 },
    ]"
    class="gl-rounded-full gl-mr-3 gl-relative gl-p-2"
  >
    <gl-loading-icon v-if="isLoading" size="sm" inline class="gl-display-block" />
    <gl-icon
      v-else
      :name="$options.EXTENSION_ICON_NAMES[iconName]"
      :size="size"
      :aria-label="iconAriaLabel"
      class="gl-display-block"
    />
  </div>
</template>
