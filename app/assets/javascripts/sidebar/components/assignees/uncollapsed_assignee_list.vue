<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { IssuableType } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import AttentionRequestedToggle from '../attention_requested_toggle.vue';
import AssigneeAvatarLink from './assignee_avatar_link.vue';
import UserNameWithStatus from './user_name_with_status.vue';

const DEFAULT_RENDER_COUNT = 5;

export default {
  components: {
    AttentionRequestedToggle,
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
      default: 'issue',
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
    hasOneUser() {
      if (this.showVerticalList) {
        return false;
      }

      return this.users.length === 1;
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
      if (this.showVerticalList) {
        return this.users;
      }

      const uncollapsedLength = this.showLess
        ? Math.min(this.users.length, DEFAULT_RENDER_COUNT)
        : this.users.length;
      return this.showLess ? this.users.slice(0, uncollapsedLength) : this.users;
    },
    username() {
      return `@${this.firstUser.username}`;
    },
    showVerticalList() {
      return this.glFeatures.mrAttentionRequests && this.isMergeRequest;
    },
    isMergeRequest() {
      return this.issuableType === IssuableType.MergeRequest;
    },
  },
  methods: {
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    userAvailability(u) {
      if (this.issuableType === IssuableType.MergeRequest) {
        return u?.availability || '';
      }
      return u?.status?.availability || '';
    },
    toggleAttentionRequested(data) {
      this.$emit('toggle-attention-requested', data);
    },
  },
};
</script>

<template>
  <assignee-avatar-link
    v-if="hasOneUser"
    tooltip-placement="left"
    :tooltip-has-name="false"
    :user="firstUser"
    :issuable-type="issuableType"
  >
    <div class="ml-2 gl-line-height-normal">
      <user-name-with-status :name="firstUser.name" :availability="userAvailability(firstUser)" />
      <div>{{ username }}</div>
    </div>
  </assignee-avatar-link>
  <div v-else>
    <div class="gl-display-flex gl-flex-wrap">
      <div
        v-for="(user, index) in uncollapsedUsers"
        :key="user.id"
        :class="{
          'user-item': !showVerticalList,
          'gl-mb-3': index !== users.length - 1 && showVerticalList,
        }"
        class="gl-display-inline-block"
      >
        <attention-requested-toggle
          v-if="showVerticalList"
          :user="user"
          type="assignee"
          @toggle-attention-requested="toggleAttentionRequested"
        />
        <assignee-avatar-link
          :user="user"
          :issuable-type="issuableType"
          :tooltip-has-name="!showVerticalList"
        >
          <div
            v-if="showVerticalList"
            class="gl-ml-3 gl-line-height-normal gl-display-grid"
            data-testid="username"
          >
            <user-name-with-status :name="user.name" :availability="userAvailability(user)" />
            <span>@{{ user.username }}</span>
          </div>
        </assignee-avatar-link>
      </div>
    </div>
    <div v-if="renderShowMoreSection" class="user-list-more gl-hover-text-blue-800">
      <button
        type="button"
        class="btn-link"
        data-qa-selector="more_assignees_link"
        @click="toggleShowLess"
      >
        <template v-if="showLess">
          {{ hiddenAssigneesLabel }}
        </template>
        <template v-else>{{ __('- show less') }}</template>
      </button>
    </div>
  </div>
</template>
