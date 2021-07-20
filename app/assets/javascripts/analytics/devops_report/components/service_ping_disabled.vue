<script>
import { GlEmptyState, GlSprintf, GlLink, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
    GlButton,
  },
  inject: {
    isAdmin: {
      default: false,
    },
    svgPath: {
      default: '',
    },
    docsLink: {
      default: '',
    },
    primaryButtonPath: {
      default: '',
    },
  },
};
</script>
<template>
  <gl-empty-state :title="s__('ServicePing|Service ping is off')" :svg-path="svgPath">
    <template #description>
      <gl-sprintf
        v-if="!isAdmin"
        :message="
          s__(
            'ServicePing|To view instance-level analytics, ask an admin to turn on %{docLinkStart}service ping%{docLinkEnd}.',
          )
        "
      >
        <template #docLink="{ content }">
          <gl-link :href="docsLink" target="_blank" data-testid="docs-link">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <template v-else>
        <p>
          {{ s__('ServicePing|Turn on service ping to review instance-level analytics.') }}
        </p>

        <gl-button
          category="primary"
          variant="success"
          :href="primaryButtonPath"
          data-testid="power-on-button"
        >
          {{ s__('ServicePing|Turn on service ping') }}
        </gl-button>
      </template>
    </template>
  </gl-empty-state>
</template>
