<script>
import { GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  name: 'DesignNotePin',
  components: {
    GlIcon,
  },
  props: {
    position: {
      type: Object,
      required: false,
      default: null,
    },
    label: {
      type: Number,
      required: false,
      default: null,
    },
    isResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInactive: {
      type: Boolean,
      required: false,
      default: false,
    },
    isOnImage: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
    size: {
      type: String,
      required: false,
      default: 'md',
      validator: (value) => ['sm', 'md'].includes(value),
    },
    ariaLabel: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    isNewNote() {
      return this.label === null;
    },
    pinLabel() {
      if (this.ariaLabel) {
        return this.ariaLabel;
      }

      return this.isNewNote
        ? __('Comment form position')
        : sprintf(__("Comment '%{label}' position"), { label: this.label });
    },
  },
};
</script>

<template>
  <button
    :style="position"
    :aria-label="pinLabel"
    :class="{
      'comment-indicator gl-border-0 gl-bg-transparent': isNewNote,
      'js-image-badge design-note-pin': !isNewNote,
      resolved: isResolved,
      inactive: isInactive,
      draft: isDraft,
      'on-image': isOnImage,
      'gl-absolute': position,
      small: size === 'sm',
    }"
    class="gl-flex gl-items-center gl-justify-center gl-text-sm"
    type="button"
    @mousedown="$emit('mousedown', $event)"
    @mouseup="$emit('mouseup', $event)"
    @click="$emit('click', $event)"
  >
    <gl-icon
      v-if="isNewNote"
      name="image-comment-dark"
      :size="24"
      class="gl-rounded-full gl-border-2 gl-border-solid gl-border-white gl-bg-white"
    />
    <template v-else>
      {{ label }}
    </template>
  </button>
</template>
