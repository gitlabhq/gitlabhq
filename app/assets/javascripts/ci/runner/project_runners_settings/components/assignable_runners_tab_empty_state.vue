<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { GlEmptyState } from '@gitlab/ui';

export default {
  name: 'AssignableRunnersTabEmptyState',
  components: {
    GlEmptyState,
  },
  EMPTY_STATE_SVG_URL,
};
</script>
<template>
  <gl-empty-state
    :svg-path="$options.EMPTY_STATE_SVG_URL"
    :title="s__('Runners|No project runners found')"
  >
    <template #description>
      {{ s__('Runners|No project runners are available to be assigned to this project.') }}
    </template>
  </gl-empty-state>
</template>
