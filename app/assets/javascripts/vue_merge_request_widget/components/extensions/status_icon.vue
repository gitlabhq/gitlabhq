<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { EXTENSION_ICON_CLASS, EXTENSION_ICONS } from '../../constants';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
  },
  computed: {
    iconAriaLabel() {
      const statusLabel = Object.keys(EXTENSION_ICONS).find(
        (k) => EXTENSION_ICONS[k] === this.iconName,
      );

      return `${capitalizeFirstCharacter(statusLabel)} ${this.name}`;
    },
  },
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <div
    :class="[$options.EXTENSION_ICON_CLASS[iconName], { 'mr-widget-extension-icon': !isLoading }]"
    class="align-self-center gl-rounded-full gl-mr-3 gl-relative gl-p-2"
  >
    <gl-loading-icon v-if="isLoading" size="md" inline class="gl-display-block" />
    <gl-icon
      v-else
      :name="iconName"
      :size="16"
      :aria-label="iconAriaLabel"
      class="gl-display-block"
    />
  </div>
</template>
