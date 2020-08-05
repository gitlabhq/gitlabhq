<script>
import { GlAlert, GlBadge, GlLink } from '@gitlab/ui';
import { s__ } from '../../locale';
/**
 * Renders Stuck Runners block for job's view.
 */
export default {
  components: {
    GlAlert,
    GlBadge,
    GlLink,
  },
  props: {
    hasNoRunnersForProject: {
      type: Boolean,
      required: true,
    },
    tags: {
      type: Array,
      required: false,
      default: () => [],
    },
    runnersPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasNoRunnersWithCorrespondingTags() {
      return this.tags.length > 0;
    },
    stuckData() {
      if (this.hasNoRunnersWithCorrespondingTags) {
        return {
          text: s__(`Job|This job is stuck because you don't have
                any active runners online or available with any of these tags assigned to them:`),
          dataTestId: 'job-stuck-with-tags',
          showTags: true,
        };
      } else if (this.hasNoRunnersForProject) {
        return {
          text: s__(`Job|This job is stuck because the project
                doesn't have any runners online assigned to it.`),
          dataTestId: 'job-stuck-no-runners',
          showTags: false,
        };
      }

      return {
        text: s__(`Job|This job is stuck because you don't
              have any active runners that can run this job.`),
        dataTestId: 'job-stuck-no-active-runners',
        showTags: false,
      };
    },
  },
};
</script>
<template>
  <gl-alert variant="warning" :dismissible="false">
    <p class="gl-mb-0" :data-testid="stuckData.dataTestId">
      {{ stuckData.text }}
      <template v-if="stuckData.showTags">
        <gl-badge v-for="tag in tags" :key="tag" variant="info">
          {{ tag }}
        </gl-badge>
      </template>
    </p>
    {{ __('Go to project') }}
    <gl-link v-if="runnersPath" :href="runnersPath">
      {{ __('CI settings') }}
    </gl-link>
  </gl-alert>
</template>
