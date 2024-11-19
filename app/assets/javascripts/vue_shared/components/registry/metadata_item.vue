<script>
import { GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

const sizeClasses = {
  s: 'mw-s',
  m: 'mw-m',
  l: 'mw-l',
  xl: 'mw-xl',
};

export default {
  name: 'MetadataItem',
  components: {
    GlIcon,
    GlLink,
    TooltipOnTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    icon: {
      type: String,
      required: false,
      default: null,
    },
    text: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: false,
      default: '',
    },
    size: {
      type: String,
      required: false,
      default: 's',
      validator(value) {
        return !value || ['s', 'm', 'l', 'xl'].includes(value);
      },
    },
    textTooltip: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    sizeClass() {
      return sizeClasses[this.size];
    },
  },
};
</script>

<template>
  <div class="gl-inline-flex gl-items-center">
    <gl-icon v-if="icon" :name="icon" class="gl-mr-3 gl-min-w-5" variant="subtle" />
    <tooltip-on-truncate v-if="link" :title="text" class="gl-truncate" :class="sizeClass">
      <gl-link :href="link" class="gl-font-bold">
        {{ text }}
      </gl-link>
    </tooltip-on-truncate>
    <div
      v-else
      data-testid="metadata-item-text"
      class="gl-inline-flex gl-font-bold"
      :class="sizeClass"
    >
      <tooltip-on-truncate v-if="!textTooltip" :title="text" class="gl-truncate">
        {{ text }}
      </tooltip-on-truncate>
      <span v-else v-gl-tooltip="{ title: textTooltip }" data-testid="text-tooltip-container">
        {{ text }}</span
      >
    </div>
  </div>
</template>
