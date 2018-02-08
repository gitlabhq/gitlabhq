<script>
  import icon from '../../vue_shared/components/icon.vue';

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
        return `multi-file-changed-icon ${this.file.tempFile ? 'multi-file-addition' : 'multi-file-modified'}`;
      },
    },
  };
</script>

<template>
  <icon
    :name="changedIcon"
    :size="12"
    :css-classes="changedIconClass"
  />
</template>
