<script>
import {
  GlBadge,
  GlButton,
  GlButtonGroup,
  GlLink,
  GlPopover,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

export default {
  i18n: {
    jobArtifacts: s__('Job|Job artifacts'),
    artifactsHelpText: s__(
      'Job|Job artifacts are files that are configured to be uploaded when a job finishes execution. Artifacts could be compiled files, unit tests or scanning reports, or any other files generated by a job.',
    ),
    expiredText: s__('Job|The artifacts were removed'),
    willExpireText: s__('Job|The artifacts will be removed'),
    lockedText: s__(
      'Job|These artifacts are the latest. They will not be deleted (even if expired) until newer artifacts are available.',
    ),
    keepText: s__('Job|Keep'),
    downloadText: s__('Job|Download'),
    browseText: s__('Job|Browse'),
    sastTooltipText: s__('Job|This artifact contains SAST scan results in JSON format.'),
  },
  artifactsHelpPath: helpPagePath('ci/jobs/job_artifacts'),
  components: {
    GlBadge,
    GlButton,
    GlButtonGroup,
    GlLink,
    GlPopover,
    TimeagoTooltip,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    artifact: {
      type: Object,
      required: true,
    },
    helpUrl: {
      type: String,
      required: true,
    },
    reports: {
      type: Array,
      required: true,
    },
  },
  computed: {
    isExpired() {
      return this.artifact?.expired && !this.isLocked;
    },
    isLocked() {
      return this.artifact?.locked;
    },
    // Only when the key is `false` we can render this block
    willExpire() {
      return this.artifact?.expired === false && !this.isLocked;
    },
    sastReport() {
      return this.reports.find((report) => report.file_type === 'sast');
    },
    dastReport() {
      return this.reports.find((report) => report.file_type === 'dast');
    },
    hasArtifactPaths() {
      return (
        Boolean(this.artifact.keepPath) ||
        Boolean(this.artifact.downloadPath) ||
        Boolean(this.artifact.browsePath)
      );
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-flex gl-items-center">
      <div class="title gl-font-bold">
        <span class="gl-mr-2">{{ $options.i18n.jobArtifacts }}</span>
        <gl-link :href="$options.artifactsHelpPath" data-testid="artifacts-help-link">
          <help-icon id="artifacts-help" />
        </gl-link>
        <gl-popover
          target="artifacts-help"
          :title="$options.i18n.jobArtifacts"
          triggers="hover focus"
        >
          {{ $options.i18n.artifactsHelpText }}
        </gl-popover>
      </div>
      <span v-if="sastReport" class="gl-ml-3">
        <gl-badge v-gl-tooltip :title="$options.i18n.sastTooltipText">
          {{ sastReport.file_type }}
        </gl-badge>
      </span>
      <span v-if="dastReport" class="gl-ml-3">
        <gl-badge>
          {{ dastReport.file_type }}
        </gl-badge>
      </span>
    </div>

    <p
      v-if="isExpired || willExpire"
      class="build-detail-row"
      data-testid="artifacts-remove-timeline"
    >
      <span v-if="isExpired">{{ $options.i18n.expiredText }}</span>
      <span v-if="willExpire" data-testid="artifacts-unlocked-message-content">
        {{ $options.i18n.willExpireText }}
      </span>
      <timeago-tooltip v-if="artifact.expireAt" :time="artifact.expireAt" />
      <gl-link
        :href="helpUrl"
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-testid="artifact-expired-help-link"
      >
        <help-icon />
      </gl-link>
    </p>
    <p v-else-if="isLocked" class="build-detail-row">
      <span data-testid="artifacts-locked-message-content">
        {{ $options.i18n.lockedText }}
      </span>
    </p>
    <gl-button-group
      v-if="hasArtifactPaths"
      class="gl-mt-3 gl-flex"
      :class="{ 'gl-mb-3': sastReport }"
    >
      <gl-button
        v-if="artifact.keepPath"
        :href="artifact.keepPath"
        data-method="post"
        data-testid="keep-artifacts"
        >{{ $options.i18n.keepText }}</gl-button
      >
      <gl-button
        v-if="artifact.downloadPath"
        :href="artifact.downloadPath"
        rel="nofollow"
        data-testid="download-artifacts"
        download
        >{{ $options.i18n.downloadText }}</gl-button
      >
      <gl-button
        v-if="artifact.browsePath"
        :href="artifact.browsePath"
        data-testid="browse-artifacts-button"
        >{{ $options.i18n.browseText }}</gl-button
      >
    </gl-button-group>
    <div class="gl-mt-2">
      <gl-link
        v-if="sastReport"
        :href="sastReport.download_path"
        class="!gl-text-link gl-underline"
        data-testid="download-sast-report-link"
      >
        {{ s__('Job|Download SAST report') }}
      </gl-link>
    </div>
  </div>
</template>
