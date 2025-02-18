<script>
import { GlBadge, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { SUCCESS_STATUS } from '../../../constants';

export default {
  iconSize: 12,
  i18n: {
    stuckText: s__('Jobs|Job is stuck. Check runners.'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlBadge,
    GlIcon,
    GlLink,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    jobId() {
      const id = getIdFromGraphQLId(this.job.id);
      return `#${id}`;
    },
    jobPath() {
      return this.job.detailedStatus?.detailsPath;
    },
    jobRef() {
      return this.job?.refName;
    },
    jobTags() {
      return this.job.tags;
    },
    createdByTag() {
      return this.job.createdByTag;
    },
    triggered() {
      return this.job.triggered;
    },
    isManualJob() {
      return this.job.manualJob;
    },
    successfulJob() {
      return this.job.status === SUCCESS_STATUS;
    },
    showAllowedToFailBadge() {
      return this.job.allowFailure && !this.successfulJob;
    },
    isScheduledJob() {
      return Boolean(this.job.scheduledAt);
    },
    canReadJob() {
      return this.job?.userPermissions?.readBuild;
    },
    jobStuck() {
      return this.job?.stuck;
    },
  },
};
</script>

<template>
  <div>
    <div class="-gl-mx-3 -gl-mb-2 -gl-mt-3 gl-truncate gl-p-3 gl-font-normal">
      <gl-icon
        v-if="jobStuck"
        v-gl-tooltip="$options.i18n.stuckText"
        name="warning"
        :size="$options.iconSize"
        class="gl-mr-2"
        data-testid="stuck-icon"
      />

      <gl-link v-if="canReadJob" :href="jobPath" data-testid="job-id-link">
        <span class="gl-truncate">
          <span data-testid="job-name">{{ jobId }}: {{ job.name }}</span>
        </span>
      </gl-link>

      <span v-else data-testid="job-id-limited-access">{{ jobId }}: {{ job.name }}</span>
    </div>

    <div class="gl-mt-1 gl-flex gl-items-center gl-justify-end gl-text-subtle lg:gl-justify-start">
      <div v-if="jobRef" class="gl-max-w-26 gl-truncate gl-rounded-base gl-bg-strong gl-px-2">
        <gl-icon
          v-if="createdByTag"
          variant="subtle"
          name="label"
          :size="$options.iconSize"
          data-testid="label-icon"
        />
        <gl-icon
          v-else
          name="fork"
          :size="$options.iconSize"
          variant="subtle"
          data-testid="fork-icon"
        />
        <gl-link
          class="gl-text-sm gl-text-subtle gl-font-monospace hover:gl-text-subtle"
          :href="job.refPath"
          data-testid="job-ref"
          >{{ job.refName }}</gl-link
        >
      </div>
      <span v-else>{{ __('none') }}</span>
      <div class="gl-ml-2 gl-flex gl-items-center gl-rounded-base gl-bg-strong gl-px-2">
        <gl-icon class="gl-mx-2" name="commit" :size="$options.iconSize" variant="subtle" />
        <gl-link
          class="gl-text-sm gl-text-subtle gl-font-monospace hover:gl-text-subtle"
          :href="job.commitPath"
          data-testid="job-sha"
          >{{ job.shortSha }}</gl-link
        >
      </div>
    </div>

    <div class="gl-mt-2">
      <gl-badge v-for="tag in jobTags" :key="tag" variant="info" data-testid="job-tag-badge">
        {{ tag }}
      </gl-badge>
      <gl-badge v-if="triggered" variant="info" data-testid="trigger-token-job-badge"
        >{{ s__('Job|trigger token') }}
      </gl-badge>
      <gl-badge v-if="showAllowedToFailBadge" variant="warning" data-testid="fail-job-badge"
        >{{ s__('Job|allowed to fail') }}
      </gl-badge>
      <gl-badge v-if="isScheduledJob" variant="info" data-testid="delayed-job-badge"
        >{{ s__('Job|delayed') }}
      </gl-badge>
      <gl-badge v-if="isManualJob" variant="info" data-testid="manual-job-badge">
        {{ s__('Job|manual') }}
      </gl-badge>
    </div>
  </div>
</template>
