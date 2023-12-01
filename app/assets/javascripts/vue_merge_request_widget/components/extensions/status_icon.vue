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
      { 'gl-w-6': !isLoading && level === 1 },
      { 'gl-p-2': isLoading || level === 1 },
    ]"
    class="gl-mr-3 gl-p-2"
  >
    <div
      class="gl-rounded-full gl-relative gl-display-flex"
      :class="{ 'mr-widget-extension-icon': !isLoading && level === 1 }"
    >
      <div class="gl-absolute gl-top-half gl-left-50p gl-translate-x-n50 gl-display-flex gl-m-auto">
        <div class="gl-display-flex gl-m-auto gl-translate-y-n50">
          <gl-loading-icon v-if="isLoading" size="sm" inline />
          <gl-icon
            v-else
            :name="$options.EXTENSION_ICON_NAMES[iconName]"
            :size="size"
            :aria-label="iconAriaLabel"
            :data-testid="`status-${iconName}-icon`"
            class="gl-display-block"
          />
        </div>
      </div>
    </div>
  </div>
</template>
