<script>
import ImportDetailsTable from './import_details_table.vue';

export default {
  components: { ImportDetailsTable },
};
</script>

<template>
  <div>
    <h1>{{ s__('Import|GitHub import details') }}</h1>
    <import-details-table />
  </div>
</template>
