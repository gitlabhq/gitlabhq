<script>
import { GlBadge, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { SUCCESS_STATUS } from '../../../constants';

export default {
  iconSize: 12,
  badgeSize: 'sm',
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
    jobRefPath() {
      return this.job?.refPath;
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
    <div class="gl-text-truncate">
      <gl-link
        v-if="canReadJob"
        class="gl-text-gray-500!"
        :href="jobPath"
        data-testid="job-id-link"
      >
        {{ jobId }}
      </gl-link>

      <span v-else data-testid="job-id-limited-access">{{ jobId }}</span>

      <gl-icon
        v-if="jobStuck"
        v-gl-tooltip="$options.i18n.stuckText"
        name="warning"
        :size="$options.iconSize"
        data-testid="stuck-icon"
      />

      <div
        class="gl-display-flex gl-align-items-center gl-lg-justify-content-start gl-justify-content-end"
      >
        <div v-if="jobRef" class="gl-max-w-15 gl-text-truncate">
          <gl-icon
            v-if="createdByTag"
            name="label"
            :size="$options.iconSize"
            data-testid="label-icon"
          />
          <gl-icon v-else name="fork" :size="$options.iconSize" data-testid="fork-icon" />
          <gl-link
            class="gl-font-weight-bold gl-text-gray-500!"
            :href="job.refPath"
            data-testid="job-ref"
            >{{ job.refName }}</gl-link
          >
        </div>

        <span v-else>{{ __('none') }}</span>

        <gl-icon class="gl-mx-2" name="commit" :size="$options.iconSize" />

        <gl-link :href="job.commitPath" data-testid="job-sha">{{ job.shortSha }}</gl-link>
      </div>
    </div>

    <div>
      <gl-badge
        v-for="tag in jobTags"
        :key="tag"
        variant="info"
        :size="$options.badgeSize"
        data-testid="job-tag-badge"
      >
        {{ tag }}
      </gl-badge>

      <gl-badge
        v-if="triggered"
        variant="info"
        :size="$options.badgeSize"
        data-testid="triggered-job-badge"
        >{{ s__('Job|triggered') }}
      </gl-badge>
      <gl-badge
        v-if="showAllowedToFailBadge"
        variant="warning"
        :size="$options.badgeSize"
        data-testid="fail-job-badge"
        >{{ s__('Job|allowed to fail') }}
      </gl-badge>
      <gl-badge
        v-if="isScheduledJob"
        variant="info"
        :size="$options.badgeSize"
        data-testid="delayed-job-badge"
        >{{ s__('Job|delayed') }}
      </gl-badge>
      <gl-badge
        v-if="isManualJob"
        variant="info"
        :size="$options.badgeSize"
        data-testid="manual-job-badge"
      >
        {{ s__('Job|manual') }}
      </gl-badge>
    </div>
  </div>
</template>
