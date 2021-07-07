<script>
import {
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
      'AlertManagement|There was an error while updating the assignee(s) list. Please try again.',
    ),
    UPDATE_ALERT_ASSIGNEES_ERROR: s__(
      'AlertManagement|There was an error while updating the assignee(s) of the alert. Please try again.',
    ),
    UPDATE_ALERT_ASSIGNEES_GRAPHQL_ERROR: s__(
      'AlertManagement|This assignee cannot be assigned to this alert.',
    ),
    ASSIGNEES_BLOCK: s__('AlertManagement|Alert assignee(s): %{assignees}'),
  },
  components: {
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
      return this.isDropdownShowing ? 'dropdown-menu-selectable show' : 'gl-display-none';
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
    class="alert-assignees gl-py-5 gl-w-70p"
    :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': !sidebarCollapsed }"
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
      <p
        class="gl-text-gray-900 gl-mb-2 gl-line-height-20 gl-display-flex gl-justify-content-space-between"
      >
        {{ __('Assignee') }}
        <a
          v-if="isEditable"
          ref="editButton"
          class="btn-link"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ __('Edit') }}
        </a>
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
        <p class="gl-new-dropdown-header-top">
          {{ __('Assign To') }}
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
      <div v-if="userName" class="gl-display-inline-flex gl-mt-2" data-testid="assigned-users">
        <span class="gl-relative gl-mr-4">
          <img
            :alt="userName"
            :src="userImg"
            :width="32"
            class="avatar avatar-inline gl-m-0 s32"
            data-qa-selector="avatar_image"
          />
        </span>
        <span class="gl-display-flex gl-flex-direction-column gl-overflow-hidden">
          <strong class="dropdown-menu-user-full-name">
            {{ userFullName }}
          </strong>
          <span class="dropdown-menu-user-username">@{{ userName }}</span>
        </span>
      </div>
      <span v-else class="gl-display-flex gl-align-items-center gl-line-height-normal">
        {{ __('None') }} -
        <gl-button
          class="gl-ml-2"
          href="#"
          variant="link"
          data-testid="unassigned-users"
          @click="updateAlertAssignees(currentUser)"
        >
          {{ __('assign yourself') }}
        </gl-button>
      </span>
    </div>
  </div>
</template>
