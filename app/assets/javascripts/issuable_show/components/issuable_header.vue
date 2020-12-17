<script>
import { GlIcon, GlButton, GlTooltipDirective, GlAvatarLink, GlAvatarLabeled } from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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
  },
  computed: {
    authorId() {
      return getIdFromGraphQLId(`${this.author.id}`);
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
      <div class="issuable-meta gl-display-flex gl-align-items-center">
        <div class="gl-display-inline-block">
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
          class="js-user-link gl-ml-2"
        >
          <gl-avatar-labeled
            :size="24"
            :src="author.avatarUrl"
            :label="author.name"
            class="d-none d-sm-inline-flex gl-ml-1"
          />
          <strong class="author d-sm-none d-inline">@{{ author.username }}</strong>
        </gl-avatar-link>
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
      class="detail-page-header-actions gl-display-flex gl-display-md-block"
    >
      <slot name="header-actions"></slot>
    </div>
  </div>
</template>
