<script>
import EMPTY_TRACING_SVG from '@gitlab/svgs/dist/illustrations/monitoring/tracing.svg?url';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  EMPTY_TRACING_SVG,
  name: 'TracingEmptyState',
  i18n: {
    title: s__('Tracing|Get started with Tracing'),
    description: s__('Tracing|Monitor your applications with GitLab Distributed Tracing.'),
    enableButtonText: s__('Tracing|Enable'),
  },
  components: {
    GlEmptyState,
    GlButton,
  },
};
</script>

<template>
  <gl-empty-state :title="$options.i18n.title" :svg-path="$options.EMPTY_TRACING_SVG">
    <template #description>
      <div>
        <span>{{ $options.i18n.description }}</span>
      </div>
    </template>

    <template #actions>
      <gl-button variant="confirm" class="gl-mx-2 gl-mb-3" @click="$emit('enable-tracing')">
        {{ $options.i18n.enableButtonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
