<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/pipelines_empty.svg?url';

import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('Runners|This runner has not run any jobs'),
    description: s__(
      'Runners|Make sure the runner is online and available to run jobs (not paused). Jobs display here when the runner picks them up.',
    ),
  },
  components: {
    GlEmptyState,
  },
  EMPTY_STATE_SVG_URL,
};
</script>

<template>
  <gl-empty-state :svg-path="$options.EMPTY_STATE_SVG_URL" :title="$options.i18n.title">
    <template #description>
      <p>{{ $options.i18n.description }}</p>
    </template>
  </gl-empty-state>
</template>
