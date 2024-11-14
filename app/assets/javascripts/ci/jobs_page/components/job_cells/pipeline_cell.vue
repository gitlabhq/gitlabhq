<script>
import { GlAvatar, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  i18n: {
    stageLabel: s__('Jobs|Stage'),
  },
  components: {
    GlAvatar,
    GlLink,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    pipelineId() {
      const id = getIdFromGraphQLId(this.job.pipeline.id);
      return `#${id}`;
    },
    pipelinePath() {
      return this.job.pipeline?.path;
    },
    pipelineUserAvatar() {
      return this.job.pipeline?.user?.avatarUrl;
    },
    userPath() {
      return this.job.pipeline?.user?.webPath;
    },
    showAvatar() {
      return this.job.pipeline?.user;
    },
  },
};
</script>

<template>
  <div>
    <div class="-gl-mx-3 -gl-mt-3 gl-p-3">
      <gl-link class="gl-truncate" :href="pipelinePath" data-testid="pipeline-id">
        {{ pipelineId }}
      </gl-link>

      <span class="gl-text-subtle">
        <span>{{ __('created by') }}</span>
        <gl-link v-if="showAvatar" :href="userPath" data-testid="pipeline-user-link">
          <gl-avatar :src="pipelineUserAvatar" :size="16" />
        </gl-link>
        <span v-else>{{ __('API') }}</span>
      </span>
    </div>

    <div v-if="job.stage" class="gl-mt-1 gl-truncate gl-text-sm gl-text-subtle">
      <span data-testid="job-stage-name">{{ $options.i18n.stageLabel }}: {{ job.stage.name }}</span>
    </div>
  </div>
</template>
