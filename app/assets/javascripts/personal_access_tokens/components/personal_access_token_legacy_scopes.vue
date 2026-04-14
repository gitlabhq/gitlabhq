<script>
import { GlIcon, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'PersonalAccessTokenLegacyScopes',
  components: { GlIcon, GlBadge },
  props: {
    scopes: {
      type: Array,
      required: true,
    },
  },
  methods: {
    formatScope(scope) {
      return scope.split('_').join(' ').toUpperCase();
    },
  },
  i18n: {
    scope: s__('AccessTokens|Token scope'),
    reduceScope: s__('AccessTokens|Consider reducing scope'),
  },
};
</script>

<template>
  <div class="gl-p-5">
    <gl-badge icon="error" variant="warning">{{ $options.i18n.reduceScope }}</gl-badge>

    <div v-for="(scope, index) in scopes" :key="index" class="gl-my-2">
      <div>
        <gl-icon name="check-sm" variant="success" class="gl-mr-2" />
        {{ formatScope(scope.value) }}
      </div>
    </div>
  </div>
</template>
