<script>
import BridgeEmptyState from './components/empty_state.vue';
import BridgeSidebar from './components/sidebar.vue';

export default {
  name: 'BridgePageApp',
  components: {
    BridgeEmptyState,
    BridgeSidebar,
  },
};
</script>
<template>
  <div>
    <!-- TODO: get job details and show CI header -->
    <!-- TODO: add downstream pipeline path -->
    <bridge-empty-state downstream-pipeline-path="#" />
    <bridge-sidebar />
  </div>
</template>
