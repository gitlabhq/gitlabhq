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
    backgroundClass() {
      return this.$options.EXTENSION_ICON_CLASS[this.iconName]?.backgroundClass;
    },
    iconClass() {
      return this.$options.EXTENSION_ICON_CLASS[this.iconName]?.iconClass;
    },
  },
  EXTENSION_ICON_NAMES,
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <div
    :class="{
      [backgroundClass]: !isLoading && level === 1,
      'gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center': level === 1,
    }"
    class="gl-relative gl-mr-3 gl-rounded-full"
  >
    <gl-loading-icon v-if="isLoading" size="sm" inline />
    <template v-else>
      <template v-if="level === 1">
        <svg class="gl-absolute" :class="iconClass" width="16" height="16" viewBox="0 0 16 16">
          <circle cx="8" cy="8" r="8" />
        </svg>
        <div class="gl-absolute gl-h-3 gl-w-3 gl-rounded-full gl-bg-section"></div>
      </template>
      <gl-icon
        :name="$options.EXTENSION_ICON_NAMES[iconName]"
        :size="12"
        :aria-label="iconAriaLabel"
        :data-testid="`status-${iconName}-icon`"
        class="gl-relative gl-z-1"
        :class="iconClass"
      />
    </template>
  </div>
</template>
