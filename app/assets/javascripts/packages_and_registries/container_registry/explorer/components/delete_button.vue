<script>
import { GlButton, GlLink, GlTooltip, GlSprintf } from '@gitlab/ui';

export default {
  name: 'DeleteButton',
  components: {
    GlButton,
    GlLink,
    GlTooltip,
    GlSprintf,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    tooltipTitle: {
      type: String,
      required: true,
    },
    tooltipLink: {
      type: String,
      default: '',
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    tooltipDisabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
};
</script>

<template>
  <div ref="deleteImageButton">
    <gl-button
      :disabled="disabled"
      :title="title"
      :aria-label="title"
      variant="danger"
      category="secondary"
      icon="remove"
      @click="$emit('delete')"
    />
    <gl-tooltip :target="() => $refs.deleteImageButton" :disabled="tooltipDisabled" placement="top">
      <gl-sprintf :message="tooltipTitle">
        <template #docLink="{ content }">
          <gl-link v-if="tooltipLink" :href="tooltipLink" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-tooltip>
  </div>
</template>
