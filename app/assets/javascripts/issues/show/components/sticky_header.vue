<script>
import { GlBadge, GlIntersectionObserver, GlLink, GlSprintf } from '@gitlab/ui';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { STATUS_OPEN, STATUS_REOPENED, STATUS_CLOSED, WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import { __, s__ } from '~/locale';

export default {
  WORKSPACE_PROJECT,
  components: {
    ConfidentialityBadge,
    GlBadge,
    GlIntersectionObserver,
    GlLink,
    GlSprintf,
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
    issuableState: {
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
    duplicatedToIssueUrl: {
      type: String,
      required: true,
    },
    movedToIssueUrl: {
      type: String,
      required: true,
    },
    promotedToEpicUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    isOpen() {
      return this.issuableState === STATUS_OPEN || this.issuableState === STATUS_REOPENED;
    },
    isClosed() {
      return this.issuableState === STATUS_CLOSED;
    },
    statusIcon() {
      return this.isClosed ? 'issue-close' : 'issue-open-m';
    },
    statusText() {
      if (this.isOpen) {
        return __('Open');
      }
      if (this.closedStatusLink) {
        return s__('IssuableStatus|Closed (%{link})');
      }
      return s__('IssuableStatus|Closed');
    },
    closedStatusLink() {
      return this.duplicatedToIssueUrl || this.movedToIssueUrl || this.promotedToEpicUrl;
    },
    closedStatusText() {
      if (this.duplicatedToIssueUrl) {
        return s__('IssuableStatus|duplicated');
      }
      if (this.movedToIssueUrl) {
        return s__('IssuableStatus|moved');
      }
      if (this.promotedToEpicUrl) {
        return s__('IssuableStatus|promoted');
      }
      return '';
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
            <gl-sprintf v-if="closedStatusLink" :message="statusText">
              <template #link>
                <gl-link
                  data-testid="sticky-header-closed-status-link"
                  class="!gl-text-inherit gl-underline"
                  :href="closedStatusLink"
                  >{{ closedStatusText }}</gl-link
                >
              </template>
            </gl-sprintf>
            <template v-else>{{ statusText }}</template>
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
