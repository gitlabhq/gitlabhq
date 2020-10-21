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
  <gl-empty-state class="js-empty-state" :title="__('Usage ping is off')" :svg-path="svgPath">
    <template #description>
      <gl-sprintf
        v-if="!isAdmin"
        :message="
          __(
            'To view instance-level analytics, ask an admin to turn on %{docLinkStart}usage ping%{docLinkEnd}.',
          )
        "
      >
        <template #docLink="{content}">
          <gl-link :href="docsLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <template v-else
        ><p>
          {{ __('Turn on usage ping to review instance-level analytics.') }}
        </p>

        <gl-button category="primary" variant="success" :href="primaryButtonPath">
          {{ __('Turn on usage ping') }}</gl-button
        >
      </template>
    </template>
  </gl-empty-state>
</template>
