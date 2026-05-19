<script>
import { GlIcon, GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import {
  SCAN_PROFILE_CATEGORIES,
  SCAN_PROFILE_SCANNER_HEALTH_ACTIVE,
  SCAN_PROFILE_SCANNER_HEALTH_FAILED,
  SCAN_PROFILE_SCANNER_HEALTH_PENDING,
  SCAN_PROFILE_SCANNER_HEALTH_STALE,
  SCAN_PROFILE_SCANNER_HEALTH_UNCONFIGURED,
  SCAN_PROFILE_SCANNER_HEALTH_WARNING,
  EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK,
} from '~/security_configuration/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'ScanTypeCell',
  components: {
    GlIcon,
    GlPopover,
    GlLink,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
  props: {
    scanType: {
      type: String,
      required: true,
    },
    isConfigured: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    popoverTargetId() {
      // eslint-disable-next-line no-underscore-dangle
      return `scanner-info-${this.scanType}-${this._uid}`;
    },
    scannerMetadata() {
      return SCAN_PROFILE_CATEGORIES[this.scanType] || {};
    },
    scanTypeBadgeClass() {
      if (this.glFeatures.securityScanProfilesStatusIndicators) {
        const classMap = {
          [SCAN_PROFILE_SCANNER_HEALTH_ACTIVE]:
            'gl-border-feedback-success gl-bg-status-success gl-text-status-success',
          [SCAN_PROFILE_SCANNER_HEALTH_WARNING]:
            'gl-border-feedback-warning gl-bg-status-warning gl-text-status-warning',
          [SCAN_PROFILE_SCANNER_HEALTH_FAILED]:
            'gl-border-feedback-danger gl-bg-status-danger gl-text-status-danger',
          [SCAN_PROFILE_SCANNER_HEALTH_PENDING]:
            'gl-border-strong gl-bg-status-neutral gl-text-strong',
          [SCAN_PROFILE_SCANNER_HEALTH_STALE]:
            'gl-border-strong gl-bg-status-neutral gl-text-strong',
          [SCAN_PROFILE_SCANNER_HEALTH_UNCONFIGURED]:
            'gl-border-dashed gl-border-strong gl-bg-default gl-text-strong',
        };
        return (
          classMap[this.status] || 'gl-border-dashed gl-border-strong gl-bg-default gl-text-strong'
        );
      }
      return this.isConfigured
        ? 'gl-border-green-500 gl-bg-green-100 gl-text-green-800'
        : 'gl-border-dashed gl-border-strong gl-bg-default gl-text-strong';
    },
  },
  EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK,
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <div
      data-testid="scan-type-badge"
      class="gl-border gl-mr-3 gl-flex gl-h-7 gl-w-7 gl-items-center gl-justify-center gl-rounded-lg gl-p-2"
      :class="scanTypeBadgeClass"
    >
      <span class="gl-font-weight-bold gl-text-xs">{{ scannerMetadata.label }}</span>
    </div>
    <span class="gl-font-bold">{{ scannerMetadata.displayName }}</span>
    <gl-icon :id="popoverTargetId" name="information-o" variant="info" class="gl-ml-2" />
    <gl-popover :target="popoverTargetId" placement="top" :title="scannerMetadata.helpTitle">
      <gl-sprintf :message="scannerMetadata.helpDescription">
        <template #link="{ content }">
          <gl-link
            :href="scannerMetadata.helpLink"
            :data-event-tracking="$options.EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK"
            data-event-label="scanner_help"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-popover>
  </div>
</template>
