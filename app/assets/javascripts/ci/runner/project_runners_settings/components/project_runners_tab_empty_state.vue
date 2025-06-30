<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { GlEmptyState, GlSprintf } from '@gitlab/ui';

export default {
  name: 'ProjectRunnersTabEmptyState',
  components: {
    GlEmptyState,
    GlSprintf,
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
      {{ __('This project does not have any project runners yet.') }}
      <gl-sprintf
        :message="
          s__('Runners|To add them, select %{strongStart}Create project runner%{strongEnd}.')
        "
      >
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
