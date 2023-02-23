<script>
import { SIDEBAR_PORTAL_ID, portalState } from '../constants';

export default {
  mounted() {
    portalState.ready = true;
  },
  beforeDestroy() {
    portalState.ready = false;
  },
  mountId: SIDEBAR_PORTAL_ID,
};
</script>

<template>
  <div v-once :id="$options.mountId"></div>
</template>
