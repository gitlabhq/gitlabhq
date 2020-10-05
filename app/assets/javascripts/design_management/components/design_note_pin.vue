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
      required: true,
    },
    label: {
      type: Number,
      required: false,
      default: null,
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
      'btn-transparent comment-indicator gl-p-0': isNewNote,
      'js-image-badge badge badge-pill': !isNewNote,
    }"
    class="gl-absolute gl-display-flex gl-align-items-center gl-justify-content-center gl-font-lg gl-outline-0!"
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
