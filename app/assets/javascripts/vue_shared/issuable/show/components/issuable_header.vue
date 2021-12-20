<script>
import { GlIcon, GlButton, GlTooltipDirective, GlAvatarLink, GlAvatarLabeled } from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isExternal } from '~/lib/utils/url_utility';
import { n__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlIcon,
    GlButton,
    GlAvatarLink,
    GlAvatarLabeled,
    TimeAgoTooltip,
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
    statusBadgeClass: {
      type: String,
      required: false,
      default: '',
    },
    statusIcon: {
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
  },
  computed: {
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
          '%{completedCount} of %{count} task completed',
          '%{completedCount} of %{count} tasks completed',
          count,
        ),
        { completedCount, count },
      );
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
      <div data-testid="status" class="issuable-status-box status-box" :class="statusBadgeClass">
        <gl-icon v-if="statusIcon" :name="statusIcon" class="d-block d-sm-none" />
        <span class="d-none d-sm-block"><slot name="status-badge"></slot></span>
      </div>
      <div class="issuable-meta gl-display-flex gl-align-items-center d-md-inline-block">
        <div v-if="blocked || confidential" class="gl-display-inline-block">
          <div v-if="blocked" data-testid="blocked" class="issuable-warning-icon inline">
            <gl-icon name="lock" :aria-label="__('Blocked')" />
          </div>
          <div v-if="confidential" data-testid="confidential" class="issuable-warning-icon inline">
            <gl-icon name="eye-slash" :aria-label="__('Confidential')" />
          </div>
        </div>
        <span>
          {{ __('Opened') }}
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
            class="d-none d-sm-inline-flex gl-mx-1"
          >
            <template #meta>
              <gl-icon v-if="isAuthorExternal" name="external-link" />
            </template>
          </gl-avatar-labeled>
          <strong class="author d-sm-none d-inline">@{{ author.username }}</strong>
        </gl-avatar-link>
        <span
          v-if="taskCompletionStatus"
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
