<script>
import { GlBadge, GlSprintf, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { sprintf } from '~/locale';
import { OS_VERSION_LABEL, WINDOWS_BUILD_LABELS } from '../../constants/index';

export default {
  name: 'PlatformBadge',
  components: { GlBadge, GlSprintf, GlTooltip },
  props: {
    platform: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    OS_VERSION_LABEL,
  },
  data() {
    return {
      badgeId: uniqueId('platform-badge-'),
    };
  },
  computed: {
    osVersionLabel() {
      return sprintf(OS_VERSION_LABEL, {
        osVersion: this.platform.osVersion,
        strongStart: '',
        strongEnd: '',
      });
    },
    platformText() {
      const { os, architecture, variant } = this.platform;
      let text = `${os}/${architecture}`;

      if (variant) {
        text += `/${variant}`;
      }

      const suffix = this.windowsBuildLabel || this.windowsBuildNumber || this.platform.osVersion;
      if (suffix) {
        text += ` (${suffix})`;
      }

      return text;
    },
    shouldDisplayTooltip() {
      return this.platform.osVersion && !this.windowsBuildLabel;
    },
    windowsBuildLabel() {
      if (this.windowsBuildNumber) {
        return WINDOWS_BUILD_LABELS[this.windowsBuildNumber];
      }
      return null;
    },
    windowsBuildNumber() {
      const { os, osVersion } = this.platform;
      if (os === 'windows' && osVersion) {
        const match = osVersion.match(/^\d+\.\d+\.(\d+)\.\d+$/);
        if (match) {
          return parseInt(match[1], 10);
        }
      }
      return null;
    },
  },
};
</script>

<template>
  <div class="gl-inline-block">
    <gl-badge :id="badgeId" :tag="shouldDisplayTooltip ? 'button' : 'span'" class="gl-border-0">
      <span data-testid="platform-badge-text">{{ platformText }}</span>
      <span v-if="shouldDisplayTooltip" class="gl-sr-only">
        {{ osVersionLabel }}
      </span>
    </gl-badge>
    <gl-tooltip v-if="shouldDisplayTooltip" :target="badgeId">
      <div class="gl-flex gl-gap-2 gl-overflow-x-auto gl-whitespace-nowrap">
        <gl-sprintf :message="$options.i18n.OS_VERSION_LABEL">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #osVersion>
            {{ platform.osVersion }}
          </template>
        </gl-sprintf>
      </div>
    </gl-tooltip>
  </div>
</template>
