<script>
import { SCAN_PROFILE_PROMO_ITEMS } from '~/security_configuration/constants';
import ScanProfileTable from './scan_profile_table.vue';

export default {
  name: 'ScanProfileConfiguration',
  components: {
    ScanProfileTable,
  },
  tableItems: SCAN_PROFILE_PROMO_ITEMS,
};
</script>
<template>
  <scan-profile-table :table-items="$options.tableItems" />
</template>
