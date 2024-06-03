<script>
export default {
  name: 'BoardCutLine',
  props: {
    cutLineText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="board-cut-line gl-display-flex gl-mb-3 gl-text-red-700 gl-align-items-center">
    <span class="gl-px-2 gl-font-sm gl-font-bold" data-testid="cut-line-text">{{
      cutLineText
    }}</span>
  </div>
</template>
