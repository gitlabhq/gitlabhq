<script>
import icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    icon,
  },
  props: {
    files: {
      type: Array,
      required: true,
    },
    icon: {
      type: String,
      required: true,
    },
  },
  computed: {
    addedFilesLength() {
      return this.files.filter(f => f.tempFile).length;
    },
    modifiedFilesLength() {
      return this.files.filter(f => !f.tempFile).length;
    },
    addedFilesIconClass() {
      return this.addedFilesLength ? 'multi-file-addition' : '';
    },
    modifiedFilesClass() {
      return this.modifiedFilesLength ? 'multi-file-modified' : '';
    },
  },
};
</script>

<template>
  <div
    class="multi-file-commit-list-collapsed text-center"
  >
    <icon
      v-once
      :name="icon"
      :size="18"
      css-classes="append-bottom-15"
    />
    <icon
      name="file-addition"
      :size="18"
      :css-classes="addedFilesIconClass + 'append-bottom-10'"
    />
    {{ addedFilesLength }}
    <icon
      name="file-modified"
      :size="18"
      :css-classes="modifiedFilesClass + ' prepend-top-10 append-bottom-10'"
    />
    {{ modifiedFilesLength }}
  </div>
</template>
