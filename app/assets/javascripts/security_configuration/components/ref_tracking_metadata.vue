<script>
import { GlBadge, GlIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'RefTrackingMetadata',
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    ProtectedBadge,
    TimeAgoTooltip,
  },
  props: {
    trackedRef: {
      type: Object,
      required: true,
    },
    disableCommitLink: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    refIcon() {
      return this.refType === 'tag' ? 'tag' : 'branch';
    },
    refTypeText() {
      return this.refType === 'tag'
        ? s__('SecurityTrackedRefs|tag')
        : s__('SecurityTrackedRefs|branch');
    },
    refType() {
      return this.trackedRef.refType.toLowerCase() === 'tag' ? 'tag' : 'branch';
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-4 gl-flex gl-flex-wrap gl-items-center gl-gap-2">
      <h4 class="gl-m-0 gl-text-base gl-font-bold" data-testid="ref-name">
        {{ trackedRef.name }}
      </h4>
      <gl-badge v-if="trackedRef.isDefault" variant="info">
        {{ s__('SecurityTrackedRefs|default') }}
      </gl-badge>
      <protected-badge v-if="trackedRef.isProtected" />
    </div>

    <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2 gl-text-sm gl-text-subtle">
      <span
        class="gl-inline-flex gl-items-center gl-gap-1 gl-rounded-base gl-bg-strong gl-px-2"
        data-testid="ref-type"
      >
        <gl-icon :name="refIcon" :size="12" />
        <span>{{ refTypeText }}</span>
      </span>

      <span aria-hidden="true">·</span>

      <span
        class="gl-inline-flex gl-items-center gl-gap-1 gl-rounded-base gl-bg-strong gl-px-2"
        data-testid="commit-short-id"
      >
        <gl-icon name="commit" :size="12" />
        <gl-link
          v-if="!disableCommitLink"
          :href="trackedRef.commit.webPath"
          class="gl-text-subtle"
          >{{ trackedRef.commit.shortId }}</gl-link
        >
        <span v-else class="gl-text-subtle">{{ trackedRef.commit.shortId }}</span>
      </span>

      <span aria-hidden="true">·</span>

      <span class="gl-line-clamp-1" data-testid="commit-title">{{ trackedRef.commit.title }}</span>

      <span aria-hidden="true">·</span>

      <time-ago-tooltip :time="trackedRef.commit.authoredDate" />
    </div>
  </div>
</template>
