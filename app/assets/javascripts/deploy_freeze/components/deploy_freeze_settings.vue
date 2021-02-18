<script>
import DeployFreezeModal from './deploy_freeze_modal.vue';
import DeployFreezeTable from './deploy_freeze_table.vue';

export default {
  components: {
    DeployFreezeTable,
    DeployFreezeModal,
  },
};
</script>

<template>
  <div>
    <deploy-freeze-table />
    <deploy-freeze-modal />
  </div>
</template>
