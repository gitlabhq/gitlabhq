<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    emojis: {
      type: Array,
      required: true,
    },
    renderGroup: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    clickEmoji(emoji) {
      this.$emit('emoji-click', emoji);
    },
  },
};
</script>

<template>
  <div class="gl-mb-2 gl-flex gl-flex-wrap">
    <template v-if="renderGroup">
      <gl-button
        v-for="emoji in emojis"
        :key="emoji"
        type="button"
        category="tertiary"
        class="emoji-picker-emoji"
        :aria-label="emoji"
        data-testid="emoji-button"
        button-text-classes="!gl-hidden"
        @click="clickEmoji(emoji)"
        @keydown.enter="clickEmoji(emoji)"
      >
        <template #emoji>
          <gl-emoji :data-name="emoji" class="!gl-mr-0" />
        </template>
      </gl-button>
    </template>
  </div>
</template>
