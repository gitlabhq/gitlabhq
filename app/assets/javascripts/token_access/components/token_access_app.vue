<script>
import { GlIntersectionObserver } from '@gitlab/ui';
import TokenPermissions from './token_permissions.vue';
import InboundTokenAccess from './inbound_token_access.vue';
import AuthLog from './auth_log.vue';

export default {
  components: {
    GlIntersectionObserver,
    AuthLog,
    InboundTokenAccess,
    TokenPermissions,
  },
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
      <inbound-token-access />
      <auth-log />
      <token-permissions class="gl-mt-5" />
    </template>
  </gl-intersection-observer>
</template>
