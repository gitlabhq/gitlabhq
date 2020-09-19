<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

export default {
  name: 'MetadataItem',
  components: {
    GlIcon,
    GlLink,
    TooltipOnTruncate,
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
        return !value || ['xs', 's', 'm', 'l', 'xl'].includes(value);
      },
    },
  },
  computed: {
    sizeClass() {
      return `mw-${this.size}`;
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-flex gl-align-items-center">
    <gl-icon v-if="icon" :name="icon" class="gl-text-gray-500 gl-mr-3" />
    <tooltip-on-truncate v-if="link" :title="text" class="gl-text-truncate" :class="sizeClass">
      <gl-link :href="link" class="gl-font-weight-bold">
        {{ text }}
      </gl-link>
    </tooltip-on-truncate>
    <div
      v-else
      data-testid="metadata-item-text"
      class="gl-font-weight-bold gl-display-inline-flex"
      :class="sizeClass"
    >
      <tooltip-on-truncate :title="text" class="gl-text-truncate">
        {{ text }}
      </tooltip-on-truncate>
    </div>
  </div>
</template>
