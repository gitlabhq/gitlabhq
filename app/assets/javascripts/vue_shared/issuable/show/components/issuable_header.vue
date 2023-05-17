<script>
import {
  GlIcon,
  GlBadge,
  GlButton,
  GlTooltipDirective,
  GlAvatarLink,
  GlAvatarLabeled,
} from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_OPEN } from '~/issues/constants';
import { isExternal } from '~/lib/utils/url_utility';
import { n__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  components: {
    GlIcon,
    GlBadge,
    GlButton,
    GlAvatarLink,
    GlAvatarLabeled,
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
  },
  computed: {
    badgeVariant() {
      return this.issuableState === STATUS_OPEN ? 'success' : 'info';
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
      if (this.toggleSidebarButtonEl) {
        this.toggleSidebarButtonEl.dispatchEvent(new Event('click'));
      }
    },
  },
};
</script>

<template>
  <div class="detail-page-header">
    <div class="detail-page-header-body">
      <gl-badge class="issuable-status-badge gl-mr-3" :variant="badgeVariant">
        <gl-icon v-if="statusIcon" :name="statusIcon" :class="statusIconClass" />
        <span class="gl-display-none gl-sm-display-block"><slot name="status-badge"></slot></span>
      </gl-badge>
      <div class="issuable-meta gl-display-flex! gl-align-items-center">
        <div v-if="blocked || confidential" class="gl-display-inline-block">
          <div v-if="blocked" data-testid="blocked" class="issuable-warning-icon inline">
            <gl-icon name="lock" :aria-label="__('Blocked')" />
          </div>
          <div v-if="confidential" data-testid="confidential" class="issuable-warning-icon inline">
            <gl-icon name="eye-slash" :aria-label="__('Confidential')" />
          </div>
        </div>
        <span>
          <template v-if="showWorkItemTypeIcon">
            <work-item-type-icon :work-item-type="issuableType" show-text />
            {{ __('created') }}
          </template>
          <template v-else>
            {{ __('Created') }}
          </template>
          <time-ago-tooltip data-testid="startTimeItem" :time="createdAt" />
          {{ __('by') }}
        </span>
        <gl-avatar-link
          data-testid="avatar"
          :data-user-id="authorId"
          :data-username="author.username"
          :data-name="author.name"
          :href="author.webUrl"
          target="_blank"
          class="js-user-link gl-vertical-align-middle gl-ml-2"
        >
          <gl-avatar-labeled
            :size="24"
            :src="author.avatarUrl"
            :label="author.name"
            :class="[{ 'gl-display-none': !isAuthorExternal }, 'gl-sm-display-inline-flex gl-mx-1']"
          >
            <template #meta>
              <gl-icon v-if="isAuthorExternal" name="external-link" class="gl-ml-1" />
            </template>
          </gl-avatar-labeled>
          <strong v-if="author.username" class="author gl-display-inline gl-sm-display-none!"
            >@{{ author.username }}</strong
          >
        </gl-avatar-link>
        <span
          v-if="taskCompletionStatus && hasTasks"
          data-testid="task-status"
          class="gl-display-none gl-md-display-block gl-lg-display-inline-block"
          >{{ taskStatusString }}</span
        >
      </div>
      <gl-button
        data-testid="sidebar-toggle"
        icon="chevron-double-lg-left"
        class="d-block d-sm-none gutter-toggle issuable-gutter-toggle"
        :aria-label="__('Expand sidebar')"
        @click="handleRightSidebarToggleClick"
      />
    </div>
    <div
      data-testid="header-actions"
      class="detail-page-header-actions gl-display-flex gl-md-display-block"
    >
      <slot name="header-actions"></slot>
    </div>
  </div>
</template>
