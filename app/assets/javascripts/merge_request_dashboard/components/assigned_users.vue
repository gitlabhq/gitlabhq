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
    class: 'gl-bg-green-100 gl-text-green-500',
  },
  REQUESTED_CHANGES: {
    name: 'error',
    class: 'gl-bg-red-100 gl-text-red-500',
  },
  REVIEWED: {
    name: 'comment-lines',
    class: 'gl-bg-blue-100 gl-text-blue-500',
  },
  REVIEW_STARTED: {
    name: 'comment-dots',
    class: 'gl-bg-gray-100 gl-text-gray-500',
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
      return isCurrentUser(getIdFromGraphQLId(user.id));
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
          <gl-avatar :src="user.avatarUrl" :size="32" />
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
            :class="reviewStateIcon(user).class"
            data-testid="review-state-icon"
          >
            <gl-icon :name="reviewStateIcon(user).name" class="gl-block" :size="12" />
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
