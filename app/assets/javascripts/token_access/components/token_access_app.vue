<script>
import OutboundTokenAccess from './outbound_token_access.vue';
import InboundTokenAccess from './inbound_token_access.vue';

export default {
  name: 'TokenAccessApp',
  components: {
    OutboundTokenAccess,
    InboundTokenAccess,
  },
};
</script>
<template>
  <div>
    <inbound-token-access />
    <outbound-token-access />
  </div>
</template>
