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
    <span class="cgreen"> +{{ file.addedLines }} </span>
    <span class="cred"> -{{ file.removedLines }} </span>
  </span>
</template>

<style>
.file-row-stats {
  font-size: 12px;
}
</style>
