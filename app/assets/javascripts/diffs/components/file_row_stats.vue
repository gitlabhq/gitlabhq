<script>
export default {
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <span class="file-row-stats">
    <span data-testid="file-added-lines" class="gl-text-success"> +{{ file.addedLines }} </span>
    <span data-testid="file-removed-lines" class="gl-text-danger"> -{{ file.removedLines }} </span>
  </span>
</template>

<style>
.file-row-stats {
  font-size: 12px;
}
</style>
