<script>
import { GlEmptyState } from '@gitlab/ui';
import ERROR_STATE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-failed-md.svg?url';

export default {
  name: 'PipelinesErrorState',
  components: {
    GlEmptyState,
  },
  ERROR_STATE_SVG,
};
</script>
<template>
  <gl-empty-state
    :svg-path="$options.ERROR_STATE_SVG"
    :title="s__('Pipelines|There was an error fetching the pipelines.')"
    :description="s__('Pipelines|Try again in a few moments or contact your support team.')"
  />
</template>
