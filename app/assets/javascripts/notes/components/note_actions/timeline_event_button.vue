<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    buttonText: __('Add comment to incident timeline'),
    addError: __('Error promoting the note to timeline event: %{error}'),
    addGenericError: __('Something went wrong while promoting the note to timeline event.'),
  },
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    noteId: {
      type: [String, Number],
      required: true,
    },
    isPromotionInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    handleButtonClick() {
      this.$emit('click-promote-comment-to-event', {
        noteId: this.noteId,
        addError: this.$options.i18n.addError,
        addGenericError: this.$options.i18n.addGenericError,
      });
    },
  },
};
</script>
<template>
  <span v-gl-tooltip :title="$options.i18n.buttonText">
    <gl-button
      category="tertiary"
      icon="clock"
      :aria-label="$options.i18n.buttonText"
      :disabled="isPromotionInProgress"
      @click="handleButtonClick"
    />
  </span>
</template>
