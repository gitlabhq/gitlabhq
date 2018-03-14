<script>
  import icon from '~/vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
    computed: {
      changedIcon() {
        return this.file.tempFile ? 'file-addition' : 'file-modified';
      },
      changedIconClass() {
        return `multi-${this.changedIcon}`;
      },
    },
  };
</script>

<template>
  <icon
    :name="changedIcon"
    :size="12"
    :css-classes="`ide-file-changed-icon ${changedIconClass}`"
  />
</template>
