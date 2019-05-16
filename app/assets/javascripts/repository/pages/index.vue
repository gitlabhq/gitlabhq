<script>
import FileTable from '../components/table/index.vue';

export default {
  components: {
    FileTable,
  },
  data() {
    return {
      ref: '',
    };
  },
};
</script>

<template>
  <file-table path="/" />
</template>
