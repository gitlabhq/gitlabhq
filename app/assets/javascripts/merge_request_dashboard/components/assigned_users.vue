<script>
import { GlIcon, GlAvatarsInline, GlAvatarLink, GlAvatar, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { swapArrayItems } from '~/lib/utils/array_utility';
import { isCurrentUser } from '~/lib/utils/common_utils';

const MAX_VISIBLE_USERS = 3;
const REVIEW_STATE_ICONS = {
  APPROVED: {
    name: 'check-circle',
    backgroundClass: 'gl-bg-status-success',
    foregroundClass: 'gl-fill-status-success',
  },
  REQUESTED_CHANGES: {
    name: 'error',
    backgroundClass: 'gl-bg-status-danger',
    foregroundClass: 'gl-fill-status-danger',
  },
  REVIEWED: {
    name: 'comment-lines',
    backgroundClass: 'gl-bg-status-info',
    foregroundClass: 'gl-fill-status-info',
  },
  REVIEW_STARTED: {
    name: 'comment-dots',
    backgroundClass: 'gl-bg-status-neutral',
    foregroundClass: 'gl-fill-status-neutral',
  },
};
const USER_TOOLTIP_TITLES = {
  ASSIGNEES: __('%{strongStart}%{you}%{strongEnd}%{break}Assigned to %{name}'),
  REQUESTED_CHANGES: __('%{strongStart}%{you}%{strongEnd}%{break}%{name} requested changes'),
  REVIEWED: __('%{strongStart}%{you}%{strongEnd}%{break}%{name} left feedback'),
  APPROVED: __('%{strongStart}%{you}%{strongEnd}%{break}Approved by %{name}'),
  UNREVIEWED: __('%{strongStart}%{you}%{strongEnd}%{break}Review requested from %{name}'),
  REVIEW_STARTED: __('%{strongStart}%{you}%{strongEnd}%{break}%{name} started a review'),
  default: __('%{strongStart}%{you}%{strongEnd}%{break}Review requested from %{name}'),
};

export default {
  components: {
    GlIcon,
    GlAvatarsInline,
    GlAvatarLink,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['newListsEnabled'],
  props: {
    users: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    usersBadgeSrOnlyText() {
      if (this.type === 'ASSIGNEES') {
        return n__(
          '%d additional assignee',
          '%d additional assignees',
          this.users.length - MAX_VISIBLE_USERS,
        );
      }

      return n__(
        '%d additional reviewer',
        '%d additional reviewers',
        this.users.length - MAX_VISIBLE_USERS,
      );
    },
    sortedUsers() {
      const currentUserIndex = this.users.findIndex((u) => this.isCurrentUser(u));

      if (currentUserIndex === -1) return this.users;

      const addIndex = Math.min(Math.max(this.users.length - 1, 0), 2);

      return swapArrayItems(this.users, currentUserIndex, addIndex);
    },
  },
  methods: {
    isCurrentUser(user) {
      return !this.newListsEnabled && isCurrentUser(getIdFromGraphQLId(user.id));
    },
    reviewStateIcon(user) {
      return REVIEW_STATE_ICONS[user.mergeRequestInteraction?.reviewState];
    },
    tooltipTitle(user) {
      const currentUser = this.isCurrentUser(user);
      const thisIsYouText = currentUser ? __('This is you.') : '';

      let titleType;

      if (this.type === 'ASSIGNEES') {
        titleType = this.type;
      } else if (user.mergeRequestInteraction?.reviewState) {
        titleType = user.mergeRequestInteraction.reviewState;
      }

      return sprintf(
        USER_TOOLTIP_TITLES[titleType] || USER_TOOLTIP_TITLES.default,
        {
          name: user.name,
          you: thisIsYouText,
          break: currentUser ? '<br />' : '',
          strongStart: currentUser ? '<strong>' : '',
          strongEnd: currentUser ? '</strong>' : '',
        },
        false,
      );
    },
  },
  MAX_VISIBLE_USERS,
  REVIEW_STATE_ICONS,
};
</script>

<template>
  <div class="mr-users-list gl-flex gl-justify-center">
    <gl-avatars-inline
      v-if="sortedUsers.length"
      :avatars="sortedUsers"
      collapsed
      :avatar-size="32"
      :max-visible="$options.MAX_VISIBLE_USERS"
      :badge-sr-only-text="usersBadgeSrOnlyText"
      badge-tooltip-prop="name"
    >
      <template #avatar="{ avatar: user }">
        <gl-avatar-link
          v-gl-tooltip.viewport.top.html="tooltipTitle(user)"
          target="blank"
          :href="user.webUrl"
          class="gl-relative"
          data-testid="assigned-user"
        >
          <gl-avatar :src="user.avatarUrl" :size="32" class="!gl-bg-white" />
          <span
            v-if="isCurrentUser(user)"
            class="gl-absolute -gl-left-2 -gl-top-2 gl-flex gl-h-5 gl-w-5 gl-items-center gl-justify-center gl-rounded-full gl-bg-blue-500 gl-p-1 gl-text-white"
            data-testid="current-user"
          >
            <gl-icon name="user" class="gl-block" :size="12" />
          </span>
          <span
            v-if="reviewStateIcon(user)"
            class="gl-absolute -gl-bottom-2 -gl-right-2 gl-flex gl-h-5 gl-w-5 gl-items-center gl-justify-center gl-rounded-full gl-p-1"
            :class="reviewStateIcon(user).backgroundClass"
            data-testid="review-state-icon"
          >
            <gl-icon
              :name="reviewStateIcon(user).name"
              class="gl-block"
              :class="reviewStateIcon(user).foregroundClass"
              :size="12"
            />
          </span>
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>
    <gl-icon v-else name="dash" />
  </div>
</template>

<style>
.mr-users-list .gl-avatars-inline-child,
.mr-users-list .gl-avatars-inline-badge,
.mr-users-list .gl-avatar-link {
  -webkit-mask: none !important;
  mask: none !important;
}

.mr-users-list .gl-avatar {
  outline: 2px solid var(--white);
  outline-offset: 0;
}
</style>
