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
  <div class="board-cut-line gl-mb-3 gl-flex gl-items-center gl-text-red-700">
    <span class="gl-px-2 gl-text-sm gl-font-bold" data-testid="cut-line-text">{{
      cutLineText
    }}</span>
  </div>
</template>
