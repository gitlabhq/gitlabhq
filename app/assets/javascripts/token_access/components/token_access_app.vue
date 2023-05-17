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
    <inbound-token-access class="gl-pb-5" />
    <outbound-token-access class="gl-py-5" />
  </div>
</template>
