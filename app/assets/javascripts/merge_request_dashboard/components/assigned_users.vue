<script>
import {
  GlIcon,
  GlTooltipDirective,
  GlButton,
  GlDisclosureDropdown,
  GlAvatarLink,
} from '@gitlab/ui';
import { n__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import UserAvatar from './user_avatar.vue';

const MAX_VISIBLE_USERS = 4;
const USER_ORDER = {
  REQUESTED_CHANGES: 0,
  APPROVED: 1,
  REVIEWED: 2,
};

export default {
  components: {
    GlIcon,
    GlButton,
    GlAvatarLink,
    GlDisclosureDropdown,
    UserAvatar,
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
        return n__('%d additional assignee', '%d additional assignees', this.hiddenUsers.length);
      }

      return n__('%d additional reviewer', '%d additional reviewers', this.hiddenUsers.length);
    },
    showAllUsersButtonText() {
      if (this.type === 'ASSIGNEES') {
        return __('Show all assignees');
      }

      return __('Show all reviewers');
    },
    sortedUsers() {
      return this.users
        .toSorted((a, b) => {
          const aRank = USER_ORDER[a.mergeRequestInteraction?.reviewState] ?? 99;
          const bRank = USER_ORDER[b.mergeRequestInteraction?.reviewState] ?? 99;

          return aRank - bRank;
        })
        .map((u) => ({ ...u, href: u.webUrl, text: u.name }));
    },
    visibleUsers() {
      if (this.sortedUsers.length <= MAX_VISIBLE_USERS) {
        return this.sortedUsers;
      }

      return this.sortedUsers.slice(0, MAX_VISIBLE_USERS - 1);
    },
    hiddenUsers() {
      if (this.sortedUsers.length <= MAX_VISIBLE_USERS) {
        return [];
      }

      return this.sortedUsers.slice(MAX_VISIBLE_USERS - 1);
    },
  },
  methods: {
    userId(user) {
      return getIdFromGraphQLId(user.id);
    },
  },
  MAX_VISIBLE_USERS,
};
</script>

<template>
  <div class="mr-users-list gl-relative gl-flex gl-justify-center">
    <div v-if="sortedUsers.length" class="gl-flex gl-gap-2">
      <gl-avatar-link
        v-for="user in visibleUsers"
        :key="user.id"
        :data-name="user.name"
        :data-user-id="userId(user)"
        :data-username="user.username"
        target="blank"
        :href="user.webUrl"
        class="js-user-link"
        data-testid="assigned-user"
        :aria-label="user.name"
      >
        <user-avatar :user="user" />
      </gl-avatar-link>
      <span v-if="hiddenUsers.length">
        <gl-disclosure-dropdown
          ref="dropdown"
          :items="sortedUsers"
          positioning-strategy="fixed"
          placement="bottom-end"
        >
          <template #toggle>
            <gl-button
              v-gl-tooltip.top.window.hover
              :title="showAllUsersButtonText"
              :aria-label="usersBadgeSrOnlyText"
              class="!gl-h-[32px] !gl-min-w-[32px] !gl-rounded-full !gl-border-0 !gl-bg-neutral-100 !gl-p-0 !gl-text-sm !gl-text-neutral-700"
              data-testid="show-all-users"
            >
              +{{ hiddenUsers.length }}
            </gl-button>
          </template>
          <template #list-item="{ item }">
            <span class="gl-flex gl-items-center gl-gap-3 gl-font-semibold">
              <user-avatar :user="item" />
              {{ item.name }}
            </span>
          </template>
        </gl-disclosure-dropdown>
      </span>
    </div>
    <gl-icon v-else name="dash" />
  </div>
</template>

<style scoped>
/* TODO: Use max-height prop when gitlab-ui gets updated.
See https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/issues/2472 */
::v-deep .gl-new-dropdown-inner {
  max-height: 310px !important;
}
</style>
