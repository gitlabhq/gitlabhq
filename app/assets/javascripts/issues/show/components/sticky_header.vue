<script>
import { GlBadge, GlIcon, GlIntersectionObserver, GlTooltipDirective } from '@gitlab/ui';
import {
  issuableStatusText,
  STATUS_CLOSED,
  TYPE_EPIC,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

export default {
  WORKSPACE_PROJECT,
  components: {
    ConfidentialityBadge,
    GlBadge,
    GlIcon,
    GlIntersectionObserver,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
    titleHtml: {
      type: String,
      required: true,
    },
  },
  computed: {
    isClosed() {
      return this.issuableStatus === STATUS_CLOSED;
    },
    statusIcon() {
      if (this.issuableType === TYPE_EPIC) {
        return this.isClosed ? 'epic-closed' : 'epic';
      }
      return this.isClosed ? 'issue-closed' : 'issues';
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
          class="issue-sticky-header-text gl-display-flex gl-align-items-center gl-gap-2 gl-mx-auto gl-px-5"
        >
          <gl-badge :variant="statusVariant">
            <gl-icon :name="statusIcon" />
            <span class="gl-display-none gl-sm-display-block gl-ml-2">{{ statusText }}</span>
          </gl-badge>
          <span
            v-if="isLocked"
            v-gl-tooltip.bottom
            data-testid="locked"
            class="issuable-warning-icon"
            :title="__('This issue is locked. Only project members can comment.')"
          >
            <gl-icon name="lock" :aria-label="__('Locked')" />
          </span>
          <confidentiality-badge
            v-if="isConfidential"
            :issuable-type="issuableType"
            :workspace-type="$options.WORKSPACE_PROJECT"
          />
          <span
            v-if="isHidden"
            v-gl-tooltip.bottom
            :title="__('This issue is hidden because its author has been banned')"
            data-testid="hidden"
            class="issuable-warning-icon"
          >
            <gl-icon name="spam" />
          </span>
          <a
            v-safe-html="titleHtml || title"
            href="#top"
            class="gl-font-weight-bold gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis gl-my-0 gl-text-black-normal"
          >
          </a>
        </div>
      </div>
    </transition>
  </gl-intersection-observer>
</template>
