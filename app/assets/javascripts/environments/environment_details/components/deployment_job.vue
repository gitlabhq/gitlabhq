<script>
import { GlTruncate, GlLink, GlBadge, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlTruncate,
    GlLink,
    GlIcon,
  },
  props: {
    job: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    jobPath() {
      return this.job?.webPath;
    },
    pipelinePath() {
      return this.job?.pipeline?.path;
    },
  },
};
</script>
<template>
  <div
    v-if="job"
    class="gl-mb-2 gl-flex gl-flex-wrap gl-justify-end gl-gap-2 @lg/panel:gl-justify-start"
  >
    <component :is="jobPath ? 'gl-link' : 'span'" :href="jobPath">
      <gl-truncate :text="job.label" />
    </component>

    <gl-link v-if="pipelinePath" :href="pipelinePath">
      <gl-icon name="pipeline" />
      {{ job.pipeline.label }}
    </gl-link>
  </div>
  <gl-badge v-else variant="info">{{ __('API') }}</gl-badge>
</template>
