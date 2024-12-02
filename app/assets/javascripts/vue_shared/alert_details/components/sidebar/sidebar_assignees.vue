<script>
import {
  GlAvatar,
  GlIcon,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlTooltip,
  GlButton,
  GlSprintf,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { s__, __ } from '~/locale';
import alertSetAssignees from '../../graphql/mutations/alert_set_assignees.mutation.graphql';
import SidebarAssignee from './sidebar_assignee.vue';

const DATA_REFETCH_DELAY = 250;

export default {
  i18n: {
    FETCH_USERS_ERROR: s__(
      'AlertManagement|There was an error while updating the assignees list. Please try again.',
    ),
    UPDATE_ALERT_ASSIGNEES_ERROR: s__(
      'AlertManagement|There was an error while updating the assignees of the alert. Please try again.',
    ),
    UPDATE_ALERT_ASSIGNEES_GRAPHQL_ERROR: s__(
      'AlertManagement|This assignee cannot be assigned to this alert.',
    ),
    ASSIGNEES_BLOCK: s__('AlertManagement|Alert assignees: %{assignees}'),
  },
  components: {
    GlAvatar,
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    GlLoadingIcon,
    GlTooltip,
    GlButton,
    GlSprintf,
    SidebarAssignee,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    alert: {
      type: Object,
      required: true,
    },
    isEditable: {
      type: Boolean,
      required: false,
      default: true,
    },
    sidebarCollapsed: {
      type: Boolean,
      required: false,
    },
  },
  data() {
    return {
      isDropdownShowing: false,
      isDropdownSearching: false,
      isUpdating: false,
      search: '',
      users: [],
    };
  },
  computed: {
    currentUser() {
      return gon?.current_username;
    },
    userName() {
      return this.alert?.assignees?.nodes[0]?.username;
    },
    userFullName() {
      return this.alert?.assignees?.nodes[0]?.name;
    },
    userImg() {
      return this.alert?.assignees?.nodes[0]?.avatarUrl;
    },
    sortedUsers() {
      return this.users
        .map((user) => ({ ...user, active: this.isActive(user.username) }))
        .sort((a, b) => (a.active === b.active ? 0 : a.active ? -1 : 1)); // eslint-disable-line no-nested-ternary
    },
    dropdownClass() {
      return this.isDropdownShowing ? 'dropdown-menu-selectable show' : 'gl-hidden';
    },
    dropDownTitle() {
      return this.userName ?? __('Select assignee');
    },
    userListValid() {
      return !this.isDropdownSearching && this.users.length > 0;
    },
    userListEmpty() {
      return !this.isDropdownSearching && this.users.length === 0;
    },
  },
  watch: {
    search: debounce(function debouncedUserSearch() {
      this.updateAssigneesDropdown();
    }, DATA_REFETCH_DELAY),
  },
  mounted() {
    this.updateAssigneesDropdown();
  },
  methods: {
    hideDropdown() {
      this.isDropdownShowing = false;
    },
    toggleFormDropdown() {
      this.isDropdownShowing = !this.isDropdownShowing;
      const { dropdown } = this.$refs.dropdown.$refs;
      if (dropdown && this.isDropdownShowing) {
        dropdown.show();
      }
    },
    isActive(name) {
      return this.alert.assignees.nodes.some(({ username }) => username === name);
    },
    buildUrl(urlRoot, url) {
      let newUrl;
      if (urlRoot != null) {
        newUrl = urlRoot.replace(/\/$/, '') + url;
      }
      return newUrl;
    },
    updateAssigneesDropdown() {
      this.isDropdownSearching = true;
      return axios
        .get(this.buildUrl(gon.relative_url_root, '/-/autocomplete/users.json'), {
          params: {
            search: this.search,
            per_page: 20,
            active: true,
            current_user: true,
            project_id: this.projectId,
          },
        })
        .then(({ data }) => {
          this.users = data;
        })
        .catch(() => {
          this.$emit('alert-error', this.$options.i18n.FETCH_USERS_ERROR);
        })
        .finally(() => {
          this.isDropdownSearching = false;
        });
    },
    updateAlertAssignees(assignees) {
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: alertSetAssignees,
          variables: {
            iid: this.alert.iid,
            assigneeUsernames: [this.isActive(assignees) ? '' : assignees],
            fullPath: this.projectPath,
          },
        })
        .then(({ data: { issuableSetAssignees: { errors } = [] } = {} } = {}) => {
          this.hideDropdown();

          if (errors[0]) {
            this.$emit(
              'alert-error',
              `${this.$options.i18n.UPDATE_ALERT_ASSIGNEES_GRAPHQL_ERROR} ${errors[0]}.`,
            );
          }
        })
        .catch(() => {
          this.$emit('alert-error', this.$options.i18n.UPDATE_ALERT_ASSIGNEES_ERROR);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <div
    class="alert-assignees gl-w-7/10 gl-py-5"
    :class="{ 'gl-border-b-1 gl-border-b-default gl-border-b-solid': !sidebarCollapsed }"
  >
    <template v-if="sidebarCollapsed">
      <div
        ref="assignees"
        class="gl-mb-6 gl-ml-6"
        data-testid="assignees-icon"
        @click="$emit('toggle-sidebar')"
      >
        <gl-icon name="user" />
        <gl-loading-icon v-if="isUpdating" size="sm" />
      </div>
      <gl-tooltip :target="() => $refs.assignees" boundary="viewport" placement="left">
        <gl-sprintf :message="$options.i18n.ASSIGNEES_BLOCK">
          <template #assignees>
            {{ userName }}
          </template>
        </gl-sprintf>
      </gl-tooltip>
    </template>

    <div v-else>
      <p class="gl-mb-2 gl-flex gl-justify-between gl-leading-20 gl-text-default">
        {{ __('Assignee') }}
        <gl-button
          v-if="isEditable"
          ref="editButton"
          category="tertiary"
          size="small"
          class="!gl-text-default"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ __('Edit') }}
        </gl-button>
      </p>

      <gl-dropdown
        ref="dropdown"
        :text="dropDownTitle"
        class="gl-w-full"
        :class="dropdownClass"
        toggle-class="dropdown-menu-toggle"
        @keydown.esc.native="hideDropdown"
        @hide="hideDropdown"
      >
        <p class="gl-dropdown-header-top">
          {{ __('Select assignees') }}
        </p>
        <gl-search-box-by-type v-model.trim="search" :placeholder="__('Search users')" />
        <div class="dropdown-content dropdown-body">
          <template v-if="userListValid">
            <gl-dropdown-item
              :active="!userName"
              active-class="is-active"
              @click="updateAlertAssignees('')"
            >
              {{ __('Unassigned') }}
            </gl-dropdown-item>
            <gl-dropdown-divider />

            <gl-dropdown-section-header>
              {{ __('Assignee') }}
            </gl-dropdown-section-header>
            <sidebar-assignee
              v-for="user in sortedUsers"
              :key="user.username"
              :user="user"
              :active="user.active"
              @update-alert-assignees="updateAlertAssignees"
            />
          </template>
          <p v-else-if="userListEmpty" class="gl-mx-5 gl-my-4">
            {{ __('No Matching Results') }}
          </p>
          <gl-loading-icon v-else size="sm" />
        </div>
      </gl-dropdown>
    </div>

    <gl-loading-icon v-if="isUpdating" size="sm" :inline="true" />
    <div
      v-else-if="!isDropdownShowing"
      class="hide-collapsed value gl-m-0"
      :class="{ 'no-value': !userName }"
    >
      <div v-if="userName" class="gl-mt-2 gl-inline-flex" data-testid="assigned-users">
        <span class="gl-relative gl-mr-4">
          <gl-avatar :src="userImg" :size="32" :alt="userName" />
        </span>
        <span class="gl-flex gl-flex-col gl-overflow-hidden">
          <strong class="dropdown-menu-user-full-name">
            {{ userFullName }}
          </strong>
          <span class="dropdown-menu-user-username">@{{ userName }}</span>
        </span>
      </div>
      <span v-else class="gl-flex gl-items-center gl-leading-normal">
        {{ __('None') }} -
        <gl-button
          class="gl-ml-2"
          href="#"
          category="tertiary"
          variant="link"
          size="small"
          data-testid="unassigned-users"
          @click="updateAlertAssignees(currentUser)"
        >
          {{ __('assign yourself') }}
        </gl-button>
      </span>
    </div>
  </div>
</template>
