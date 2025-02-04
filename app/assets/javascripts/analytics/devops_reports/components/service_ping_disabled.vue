<script>
import { GlEmptyState, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

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
    primaryButtonPath: {
      default: '',
    },
  },
  docsLink: helpPagePath('development/internal_analytics/service_ping/_index'),
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
          <gl-link :href="$options.docsLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <template v-else>
        <p>
          {{ s__('ServicePing|Turn on service ping to review instance-level analytics.') }}
        </p>

        <gl-button category="primary" variant="confirm" :href="primaryButtonPath">
          {{ s__('ServicePing|Turn on service ping') }}
        </gl-button>
      </template>
    </template>
  </gl-empty-state>
</template>
