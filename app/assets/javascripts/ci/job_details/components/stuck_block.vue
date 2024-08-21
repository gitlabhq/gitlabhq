<script>
import { GlAlert, GlBadge, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';
/**
 * Renders Stuck Runners block for job's view.
 */
export default {
  components: {
    GlAlert,
    GlBadge,
    GlLink,
    GlSprintf,
  },
  props: {
    hasOfflineRunnersForProject: {
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
    protectedBranchSettingsDocsLink() {
      return `${DOCS_URL}/runner/security/index.html#reduce-the-security-risk-of-using-privileged-containers`;
    },
    stuckData() {
      if (this.hasNoRunnersWithCorrespondingTags) {
        return {
          text: s__(
            `Job|This job is stuck because of one of the following problems. There are no active runners online, no runners for the %{linkStart}protected branch%{linkEnd}, or no runners that match all of the job's tags:`,
          ),
          dataTestId: 'job-stuck-with-tags',
          showTags: true,
        };
      }
      if (this.hasOfflineRunnersForProject) {
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
      <gl-sprintf :message="stuckData.text">
        <template #link="{ content }">
          <a class="gl-inline-block" :href="protectedBranchSettingsDocsLink" target="_blank">
            {{ content }}
          </a>
        </template>
      </gl-sprintf>
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
