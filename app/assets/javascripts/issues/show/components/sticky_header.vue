<script>
import { GlBadge, GlIntersectionObserver, GlLink } from '@gitlab/ui';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { issuableStatusText, STATUS_CLOSED, WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

export default {
  WORKSPACE_PROJECT,
  components: {
    ConfidentialityBadge,
    GlBadge,
    GlIntersectionObserver,
    GlLink,
    HiddenBadge,
    ImportedBadge,
    LockedBadge,
  },
  props: {
    isConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    isHidden: {
      type: Boolean,
      required: false,
      default: false,
    },
    isImported: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableStatus: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
    show: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: true,
    },
  },
  computed: {
    isClosed() {
      return this.issuableStatus === STATUS_CLOSED;
    },
    statusIcon() {
      return this.isClosed ? 'issue-close' : 'issue-open-m';
    },
    statusText() {
      return issuableStatusText[this.issuableStatus];
    },
    statusVariant() {
      return this.isClosed ? 'info' : 'success';
    },
  },
};
</script>

<template>
  <gl-intersection-observer @appear="$emit('hide')" @disappear="$emit('show')">
    <transition name="issuable-header-slide">
      <div
        v-if="show"
        class="issue-sticky-header gl-border-b gl-fixed gl-z-3 gl-bg-default gl-py-3"
        data-testid="issue-sticky-header"
      >
        <div class="issue-sticky-header-text gl-mx-auto gl-flex gl-items-center gl-gap-2">
          <gl-badge :variant="statusVariant" :icon="statusIcon" class="gl-shrink-0">
            {{ statusText }}
          </gl-badge>
          <confidentiality-badge
            v-if="isConfidential"
            :issuable-type="issuableType"
            :workspace-type="$options.WORKSPACE_PROJECT"
          />
          <locked-badge v-if="isLocked" :issuable-type="issuableType" />
          <hidden-badge v-if="isHidden" :issuable-type="issuableType" />
          <imported-badge v-if="isImported" :importable-type="issuableType" />

          <gl-link class="gl-truncate gl-font-bold gl-text-default" href="#top" :title="title">
            {{ title }}
          </gl-link>
        </div>
      </div>
    </transition>
  </gl-intersection-observer>
</template>
