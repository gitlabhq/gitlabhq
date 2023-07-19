<script>
import {
  GlIcon,
  GlBadge,
  GlButton,
  GlSprintf,
  GlTooltipDirective,
  GlAvatarLink,
  GlAvatarLabeled,
} from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { issuableStatusText, STATUS_OPEN } from '~/issues/constants';
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
    GlAvatarLink,
    GlAvatarLabeled,
    GlSprintf,
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
    taskCompletionStatus: {
      type: Object,
      required: false,
      default: null,
    },
    issuableType: {
      type: String,
      required: false,
      default: '',
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
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
      return this.issuableState === STATUS_OPEN ? 'success' : 'info';
    },
    createdMessage() {
      return this.showWorkItemTypeIcon
        ? __('created %{timeAgo} by %{author}')
        : __('Created %{timeAgo} by %{author}');
    },
    authorId() {
      return getIdFromGraphQLId(`${this.author.id}`);
    },
    isAuthorExternal() {
      return isExternal(this.author.webUrl);
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
  <div class="detail-page-header gl-flex-direction-column gl-sm-flex-direction-row">
    <div class="detail-page-header-body gl-flex-wrap">
      <gl-badge class="gl-mr-2" :variant="badgeVariant">
        <gl-icon v-if="statusIcon" :name="statusIcon" :class="statusIconClass" />
        <span class="gl-display-none gl-sm-display-block" :class="{ 'gl-ml-2': statusIcon }">
          <slot name="status-badge">{{ badgeText }}</slot>
        </span>
      </gl-badge>
      <span v-if="blocked" class="issuable-warning-icon" data-testid="blocked">
        <gl-icon name="lock" :aria-label="__('Blocked')" />
      </span>
      <confidentiality-badge
        v-if="confidential"
        :issuable-type="issuableType"
        :workspace-type="workspaceType"
      />
      <work-item-type-icon v-if="showWorkItemTypeIcon" :work-item-type="issuableType" show-text />
      <gl-sprintf :message="createdMessage">
        <template #timeAgo>
          <time-ago-tooltip class="gl-mx-2" :time="createdAt" />
        </template>
        <template #author>
          <gl-avatar-link
            :data-user-id="authorId"
            :data-username="author.username"
            :data-name="author.name"
            :href="author.webUrl"
            class="js-user-link gl-vertical-align-middle gl-mx-2"
          >
            <gl-avatar-labeled
              :size="24"
              :src="author.avatarUrl"
              :label="author.name"
              :class="[
                { 'gl-display-none': !isAuthorExternal },
                'gl-sm-display-inline-flex gl-mx-1',
              ]"
            >
              <template #meta>
                <gl-icon v-if="isAuthorExternal" name="external-link" class="gl-ml-1" />
              </template>
            </gl-avatar-labeled>
            <strong v-if="author.username" class="author gl-display-inline gl-sm-display-none!"
              >@{{ author.username }}</strong
            >
          </gl-avatar-link>
        </template>
      </gl-sprintf>
      <span
        v-if="taskCompletionStatus && hasTasks"
        data-testid="task-status"
        class="gl-display-none gl-md-display-block gl-lg-display-inline-block"
        >{{ taskStatusString }}</span
      >
      <gl-button
        icon="chevron-double-lg-left"
        class="gutter-toggle gl-display-block gl-sm-display-none!"
        :aria-label="__('Expand sidebar')"
        @click="handleRightSidebarToggleClick"
      />
    </div>
    <div data-testid="header-actions" class="detail-page-header-actions gl-display-flex">
      <slot name="header-actions"></slot>
    </div>
  </div>
</template>
