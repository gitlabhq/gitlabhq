<script>
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'DesignNotePin',
  components: {
    Icon,
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
    repositioning: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isNewNote() {
      return this.label === null;
    },
    pinStyle() {
      return this.repositioning ? { ...this.position, cursor: 'move' } : this.position;
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
    :style="pinStyle"
    :aria-label="pinLabel"
    :class="{
      'btn-transparent comment-indicator': isNewNote,
      'js-image-badge badge badge-pill': !isNewNote,
    }"
    class="design-pin gl-absolute gl-display-flex gl-align-items-center gl-justify-content-center"
    type="button"
    @mousedown="$emit('mousedown', $event)"
    @mouseup="$emit('mouseup', $event)"
    @click="$emit('click', $event)"
  >
    <icon v-if="isNewNote" name="image-comment-dark" />
    <template v-else>
      {{ label }}
    </template>
  </button>
</template>
