<script>
import FileTable from '../components/table/index.vue';

export default {
  components: {
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
