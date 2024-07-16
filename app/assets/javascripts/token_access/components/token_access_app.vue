<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TokenPermissions from './token_permissions.vue';
import OutboundTokenAccess from './outbound_token_access.vue';
import InboundTokenAccess from './inbound_token_access.vue';

export default {
  name: 'TokenAccessApp',
  components: {
    InboundTokenAccess,
    OutboundTokenAccess,
    TokenPermissions,
  },
  mixins: [glFeatureFlagsMixin()],
};
</script>
<template>
  <div>
    <token-permissions v-if="glFeatures.allowPushRepositoryForJobToken" />
    <inbound-token-access />
    <outbound-token-access />
  </div>
</template>
