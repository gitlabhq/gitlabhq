<script>
import { GlIcon } from '@gitlab/ui';
import { formatTime } from '~/lib/utils/datetime_utility';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'StatusCell',
  iconSize: 12,
  i18n: {
    statusDescription: (id) => sprintf(s__('Jobs|Status for job %{id}'), { id }),
  },
  components: {
    CiIcon,
    GlIcon,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
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
    statusDescriptionId() {
      return `ci-status-description-${this.jobId}`;
    },
    finishedTime() {
      return this.job?.finishedAt;
    },
    duration() {
      return this.job?.duration;
    },
    durationFormatted() {
      return formatTime(this.duration * 1000);
    },
  },
};
</script>

<template>
  <div>
    <p :id="statusDescriptionId" class="gl-sr-only">{{ $options.i18n.statusDescription(jobId) }}</p>
    <ci-icon
      :status="job.detailedStatus"
      show-status-text
      :aria-describedby="statusDescriptionId"
    />
    <div class="gl-ml-1 gl-mt-2 gl-text-sm gl-text-subtle">
      <div v-if="duration" data-testid="job-duration">
        <gl-icon
          name="timer"
          :size="$options.iconSize"
          variant="subtle"
          data-testid="duration-icon"
        />
        {{ durationFormatted }}
      </div>
      <div v-if="finishedTime" data-testid="job-finished-time">
        <gl-icon
          name="calendar"
          :size="$options.iconSize"
          variant="subtle"
          data-testid="finished-time-icon"
        />
        <time-ago-tooltip :time="finishedTime" />
      </div>
    </div>
  </div>
</template>
