<script>
import { GlBadge, GlIcon, GlIntersectionObserver, GlLink } from '@gitlab/ui';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { issuableStatusText, STATUS_CLOSED, WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

export default {
  WORKSPACE_PROJECT,
  components: {
    ConfidentialityBadge,
    GlBadge,
    GlIcon,
    GlIntersectionObserver,
    GlLink,
    HiddenBadge,
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
        class="issue-sticky-header gl-fixed gl-z-index-3 gl-bg-white gl-border-1 gl-border-b-solid gl-border-b-gray-100 gl-py-3"
        data-testid="issue-sticky-header"
      >
        <div
          class="issue-sticky-header-text gl-display-flex gl-align-items-center gl-gap-2 gl-mx-auto"
        >
          <gl-badge :variant="statusVariant">
            <gl-icon :name="statusIcon" />
            <span class="gl-display-none gl-sm-display-block gl-ml-2">{{ statusText }}</span>
          </gl-badge>
          <confidentiality-badge
            v-if="isConfidential"
            :issuable-type="issuableType"
            :workspace-type="$options.WORKSPACE_PROJECT"
          />
          <locked-badge v-if="isLocked" :issuable-type="issuableType" />
          <hidden-badge v-if="isHidden" :issuable-type="issuableType" />
          <gl-link
            class="gl-font-weight-bold gl-text-black-normal gl-text-truncate"
            href="#top"
            :title="title"
          >
            {{ title }}
          </gl-link>
        </div>
      </div>
    </transition>
  </gl-intersection-observer>
</template>
