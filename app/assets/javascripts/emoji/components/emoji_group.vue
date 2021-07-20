<script>
export default {
  props: {
    emojis: {
      type: Array,
      required: true,
    },
    renderGroup: {
      type: Boolean,
      required: true,
    },
    clickEmoji: {
      type: Function,
      required: true,
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-deprecated-functional-template -->
<template functional>
  <div class="gl-display-flex gl-flex-wrap gl-mb-2">
    <template v-if="props.renderGroup">
      <button
        v-for="emoji in props.emojis"
        :key="emoji"
        type="button"
        class="gl-border-0 gl-bg-transparent gl-px-0 gl-py-2 gl-text-center emoji-picker-emoji"
        data-testid="emoji-button"
        @click="props.clickEmoji(emoji)"
      >
        <gl-emoji :data-name="emoji" />
      </button>
    </template>
  </div>
</template>
