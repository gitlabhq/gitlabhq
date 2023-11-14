<script>
import EMPTY_TRACING_SVG from '@gitlab/svgs/dist/illustrations/monitoring/tracing.svg?url';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  EMPTY_TRACING_SVG,
  i18n: {
    title: s__('Observability|Get started with GitLab Observability'),
    description: s__('Observability|Monitor your applications with GitLab Observability.'),
    enableButtonText: s__('Observability|Enable'),
  },
  components: {
    GlEmptyState,
    GlButton,
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="$options.EMPTY_TRACING_SVG"
    :svg-height="null"
  >
    <template #description>
      <span>{{ $options.i18n.description }}</span>
    </template>

    <template #actions>
      <gl-button variant="confirm" class="gl-mx-2 gl-mb-3" @click="$emit('enable-observability')">
        {{ $options.i18n.enableButtonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
