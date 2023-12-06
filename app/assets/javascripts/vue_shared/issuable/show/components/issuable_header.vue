<script>
import { GlIcon, GlBadge, GlButton, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { issuableStatusText, STATUS_OPEN, STATUS_REOPENED } from '~/issues/constants';
import { isExternal } from '~/lib/utils/url_utility';
import { __, n__, sprintf } from '~/locale';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  components: {
    ConfidentialityBadge,
    GlIcon,
    GlBadge,
    GlButton,
    GlLink,
    GlSprintf,
    HiddenBadge,
    LockedBadge,
    TimeAgoTooltip,
    WorkItemTypeIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    createdAt: {
      type: String,
      required: true,
    },
    author: {
      type: Object,
      required: true,
    },
    issuableState: {
      type: String,
      required: false,
      default: '',
    },
    statusIcon: {
      type: String,
      required: false,
      default: '',
    },
    statusIconClass: {
      type: String,
      required: false,
      default: '',
    },
    blocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFirstContribution: {
      type: Boolean,
      required: false,
      default: false,
    },
    isHidden: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableType: {
      type: String,
      required: false,
      default: '',
    },
    serviceDeskReplyTo: {
      type: String,
      required: false,
      default: '',
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    taskCompletionStatus: {
      type: Object,
      required: false,
      default: null,
    },
    workspaceType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    badgeText() {
      return issuableStatusText[this.issuableState];
    },
    badgeVariant() {
      return this.issuableState === STATUS_OPEN || this.issuableState === STATUS_REOPENED
        ? 'success'
        : 'info';
    },
    shouldShowWorkItemTypeIcon() {
      return this.showWorkItemTypeIcon && this.issuableType;
    },
    createdMessage() {
      if (this.serviceDeskReplyTo) {
        return this.shouldShowWorkItemTypeIcon
          ? __('created %{timeAgo} by %{email} via %{author}')
          : __('Created %{timeAgo} by %{email} via %{author}');
      }
      return this.shouldShowWorkItemTypeIcon
        ? __('created %{timeAgo} by %{author}')
        : __('Created %{timeAgo} by %{author}');
    },
    authorId() {
      return getIdFromGraphQLId(`${this.author.id}`);
    },
    isAuthorExternal() {
      return isExternal(this.author.webUrl ?? '');
    },
    taskStatusString() {
      const { count, completedCount } = this.taskCompletionStatus;

      return sprintf(
        n__(
          '%{completedCount} of %{count} checklist item completed',
          '%{completedCount} of %{count} checklist items completed',
          count,
        ),
        { completedCount, count },
      );
    },
    hasTasks() {
      return this.taskCompletionStatus.count > 0;
    },
  },
  mounted() {
    this.toggleSidebarButtonEl = document.querySelector('.js-toggle-right-sidebar-button');
  },
  methods: {
    handleRightSidebarToggleClick() {
      this.$emit('toggle');
      if (this.toggleSidebarButtonEl) {
        this.toggleSidebarButtonEl.dispatchEvent(new Event('click'));
      }
    },
  },
};
</script>

<template>
  <div class="detail-page-header gl-flex-direction-column gl-md-flex-direction-row">
    <div class="detail-page-header-body gl-flex-wrap gl-column-gap-2">
      <gl-badge :variant="badgeVariant" data-testid="issue-state-badge">
        <gl-icon v-if="statusIcon" :name="statusIcon" :class="statusIconClass" />
        <span class="gl-display-none gl-sm-display-block" :class="{ 'gl-ml-2': statusIcon }">
          <slot name="status-badge">{{ badgeText }}</slot>
        </span>
      </gl-badge>
      <confidentiality-badge
        v-if="confidential"
        :issuable-type="issuableType"
        :workspace-type="workspaceType"
      />
      <locked-badge v-if="blocked" :issuable-type="issuableType" />
      <hidden-badge v-if="isHidden" :issuable-type="issuableType" />
      <work-item-type-icon
        v-if="shouldShowWorkItemTypeIcon"
        show-text
        :work-item-type="issuableType"
      />
      <gl-sprintf :message="createdMessage">
        <template #timeAgo>
          <time-ago-tooltip :time="createdAt" />
        </template>
        <template #email>
          {{ serviceDeskReplyTo }}
        </template>
        <template #author>
          <gl-link
            class="gl-font-weight-bold js-user-link"
            :href="author.webUrl"
            :data-user-id="authorId"
          >
            <span :class="[{ 'gl-display-none': !isAuthorExternal }, 'gl-sm-display-inline']">
              {{ author.name }}
            </span>
            <gl-icon
              v-if="isAuthorExternal"
              name="external-link"
              :aria-label="__('external link')"
            />
            <strong v-if="author.username" class="author gl-display-inline gl-sm-display-none!"
              >@{{ author.username }}</strong
            >
          </gl-link>
        </template>
      </gl-sprintf>
      <gl-icon
        v-if="isFirstContribution"
        v-gl-tooltip
        name="first-contribution"
        :title="__('1st contribution!')"
        :aria-label="__('1st contribution!')"
      />
      <span
        v-if="taskCompletionStatus && hasTasks"
        class="gl-display-none gl-md-display-block gl-lg-display-inline-block"
        >{{ taskStatusString }}</span
      >
      <gl-button
        icon="chevron-double-lg-left"
        class="gl-ml-auto gl-display-block gl-sm-display-none! js-sidebar-toggle"
        :aria-label="__('Expand sidebar')"
        @click="handleRightSidebarToggleClick"
      />
    </div>
    <div class="detail-page-header-actions gl-align-self-center gl-display-flex gl-gap-3">
      <slot name="header-actions"></slot>
    </div>
  </div>
</template>
