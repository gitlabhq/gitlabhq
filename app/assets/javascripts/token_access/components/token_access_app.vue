<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import OutboundTokenAccess from './outbound_token_access.vue';
import InboundTokenAccess from './inbound_token_access.vue';
import OptInJwt from './opt_in_jwt.vue';

export default {
  components: {
    OutboundTokenAccess,
    InboundTokenAccess,
    OptInJwt,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    inboundTokenAccessEnabled() {
      return this.glFeatures.ciInboundJobTokenScope;
    },
  },
};
</script>
<template>
  <div>
    <inbound-token-access v-if="inboundTokenAccessEnabled" class="gl-pb-5" />
    <outbound-token-access class="gl-py-5" />
    <opt-in-jwt />
  </div>
</template>
