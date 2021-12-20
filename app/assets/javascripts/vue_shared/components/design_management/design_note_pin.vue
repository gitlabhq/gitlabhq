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
  },
  computed: {
    isNewNote() {
      return this.label === null;
    },
    pinLabel() {
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
      'btn-transparent comment-indicator': isNewNote,
      'js-image-badge design-note-pin': !isNewNote,
      resolved: isResolved,
      inactive: isInactive,
      'gl-absolute': position,
    }"
    class="gl-display-flex gl-align-items-center gl-justify-content-center gl-font-sm"
    type="button"
    @mousedown="$emit('mousedown', $event)"
    @mouseup="$emit('mouseup', $event)"
    @click="$emit('click', $event)"
  >
    <gl-icon v-if="isNewNote" name="image-comment-dark" :size="24" />
    <template v-else>
      {{ label }}
    </template>
  </button>
</template>
