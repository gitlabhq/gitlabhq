<script>
export default {
  name: 'FileTree',
  props: {
    fileRowComponent: {
      type: Object,
      required: true,
    },
    level: {
      type: Number,
      required: true,
    },
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    childFilesLevel() {
      return this.file.isHeader ? 0 : this.level + 1;
    },
  },
};
</script>

<template>
  <div>
    <component
      :is="fileRowComponent"
      :level="level"
      :file="file"
      v-bind="$attrs"
      v-on="$listeners"
    />
    <template v-if="file.opened || file.isHeader">
      <file-tree
        v-for="childFile in file.tree"
        :key="childFile.key"
        :file-row-component="fileRowComponent"
        :level="childFilesLevel"
        :file="childFile"
        v-bind="$attrs"
        v-on="$listeners"
      />
    </template>
  </div>
</template>
