<script>
import { GlButton } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import AssigneeAvatarLink from './assignee_avatar_link.vue';
import UserNameWithStatus from './user_name_with_status.vue';

const DEFAULT_RENDER_COUNT = 5;

export default {
  components: {
    GlButton,
    AssigneeAvatarLink,
    UserNameWithStatus,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    users: {
      type: Array,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
  },
  data() {
    return {
      showLess: true,
    };
  },
  computed: {
    firstUser() {
      return this.users[0];
    },
    hiddenAssigneesLabel() {
      const { numberOfHiddenAssignees } = this;
      return sprintf(__('+ %{numberOfHiddenAssignees} more'), { numberOfHiddenAssignees });
    },
    renderShowMoreSection() {
      return this.users.length > DEFAULT_RENDER_COUNT;
    },
    numberOfHiddenAssignees() {
      return this.users.length - DEFAULT_RENDER_COUNT;
    },
    uncollapsedUsers() {
      const uncollapsedLength = this.showLess
        ? Math.min(this.users.length, DEFAULT_RENDER_COUNT)
        : this.users.length;
      return this.showLess ? this.users.slice(0, uncollapsedLength) : this.users;
    },
    username() {
      return `@${this.firstUser.username}`;
    },
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
  },
  methods: {
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    userAvailability(u) {
      if (this.issuableType === TYPE_MERGE_REQUEST) {
        return u?.availability || '';
      }
      return u?.status?.availability || '';
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-flex-wrap">
      <div
        v-for="(user, index) in uncollapsedUsers"
        :key="user.id"
        :class="{
          'gl-mb-3': index !== users.length - 1 || users.length > 5,
        }"
        class="assignee-grid gl-grid gl-w-full gl-items-center"
      >
        <assignee-avatar-link
          :user="user"
          :issuable-type="issuableType"
          class="gl-break-anywhere"
          data-css-area="user"
        >
          <div class="gl-ml-3 gl-grid gl-items-center gl-leading-normal" data-testid="username">
            <user-name-with-status :name="user.name" :availability="userAvailability(user)" />
          </div>
        </assignee-avatar-link>
      </div>
    </div>
    <div v-if="renderShowMoreSection" class="hover:gl-text-blue-800" data-testid="user-list-more">
      <gl-button
        category="tertiary"
        size="small"
        data-testid="user-list-more-button"
        @click="toggleShowLess"
      >
        <template v-if="showLess">
          {{ hiddenAssigneesLabel }}
        </template>
        <template v-else>{{ __('- show less') }}</template>
      </gl-button>
    </div>
  </div>
</template>
