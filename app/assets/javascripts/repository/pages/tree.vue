<script>
import FileTable from '../components/table/index.vue';

export default {
  component: {
    FileTable,
  },
  props: {
    path: {
      type: String,
      required: false,
      default: '/',
    },
  },
};
</script>

<template>
  <file-table :path="path" />
</template>
