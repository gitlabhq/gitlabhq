<script>
import { GlIntersectionObserver } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import TokenPermissions from './token_permissions.vue';
import OutboundTokenAccess from './outbound_token_access.vue';
import InboundTokenAccess from './inbound_token_access.vue';
import AuthLog from './auth_log.vue';

export default {
  components: {
    GlIntersectionObserver,
    AuthLog,
    InboundTokenAccess,
    OutboundTokenAccess,
    TokenPermissions,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      isVisible: false,
    };
  },
  methods: {
    updateVisible({ isIntersecting }) {
      this.isVisible = isIntersecting;
    },
  },
};
</script>
<template>
  <gl-intersection-observer @update="updateVisible">
    <template v-if="isVisible">
      <token-permissions v-if="glFeatures.allowPushRepositoryForJobToken" />
      <inbound-token-access />
      <auth-log />
      <outbound-token-access />
    </template>
  </gl-intersection-observer>
</template>
