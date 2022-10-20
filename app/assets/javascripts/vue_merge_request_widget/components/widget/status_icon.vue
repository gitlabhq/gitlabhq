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
    iconSize() {
      return this.level === 1 ? 16 : 12;
    },
  },
  EXTENSION_ICON_NAMES,
  EXTENSION_ICON_CLASS,
};
</script>

<template>
  <div :class="[$options.EXTENSION_ICON_CLASS[iconName]]" class="gl-mr-3">
    <gl-loading-icon v-if="isLoading" size="md" inline />
    <div
      v-else
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-rounded-full gl-bg-gray-10"
      :class="{
        'gl-p-2': level === 1,
      }"
    >
      <div class="gl-rounded-full gl-bg-white">
        <gl-icon
          :name="$options.EXTENSION_ICON_NAMES[iconName]"
          :size="iconSize"
          :aria-label="iconAriaLabel"
          :data-qa-selector="`status_${iconName}_icon`"
          class="gl-display-block"
        />
      </div>
    </div>
  </div>
</template>
