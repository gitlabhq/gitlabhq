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
    clickable: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  emits: ['click'],
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
  <component
    :is="clickable ? 'button' : 'span'"
    :style="position"
    :aria-label="pinLabel"
    :class="{
      'comment-indicator gl-border-0 gl-bg-transparent gl-p-0': isNewNote,
      'js-image-badge design-note-pin gl-bg-[var(--gl-status-brand-icon-color)]': !isNewNote,
      resolved: isResolved,
      inactive: isInactive,
      draft: isDraft,
      'on-image gl-border-2 gl-border-solid gl-border-neutral-0 gl-shadow-[0_2px_4px_var(--gl-color-alpha-dark-8),0_0_1px_var(--gl-color-alpha-dark-24)]':
        isOnImage,
      'gl-absolute': position,
      'gl-h-7 gl-w-7': size === 'md',
      'small gl-h-6 gl-w-6': size === 'sm',
    }"
    class="gl-z-1 gl-flex gl-items-center gl-justify-center gl-rounded-full gl-border-0 gl-text-sm gl-font-bold gl-text-neutral-0"
    :type="clickable ? 'button' : undefined"
    @click="clickable && $emit('click', $event)"
  >
    <gl-icon
      v-if="isNewNote"
      name="image-comment-dark"
      :size="32"
      class="gl-rounded-full gl-border-2 gl-border-solid gl-border-neutral-0 gl-bg-neutral-0 gl-text-neutral-950"
    />
    <template v-else>
      {{ label }}
    </template>
  </component>
</template>
