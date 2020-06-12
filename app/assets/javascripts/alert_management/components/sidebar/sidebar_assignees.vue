<script>
import {
  GlIcon,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownHeader,
  GlDropdownItem,
  GlLoadingIcon,
  GlTooltip,
  GlButton,
  GlSprintf,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import alertSetAssignees from '../../graphql/mutations/alert_set_assignees.graphql';
import SidebarAssignee from './sidebar_assignee.vue';
import { debounce } from 'lodash';

const DATA_REFETCH_DELAY = 250;

export default {
  FETCH_USERS_ERROR: s__(
    'AlertManagement|There was an error while updating the assignee(s) list. Please try again.',
  ),
  UPDATE_ALERT_ASSIGNEES_ERROR: s__(
    'AlertManagement|There was an error while updating the assignee(s) of the alert. Please try again.',
  ),
  components: {
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownHeader,
    GlLoadingIcon,
    GlTooltip,
    GlButton,
    GlSprintf,
    SidebarAssignee,
  },
  props: {
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
    assignedUsers() {
      return this.alert.assignees.nodes.length > 0
        ? this.alert.assignees.nodes[0].username
        : s__('AlertManagement|Unassigned');
    },
    dropdownClass() {
      return this.isDropdownShowing ? 'show' : 'gl-display-none';
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
        .get(this.buildUrl(gon.relative_url_root, '/autocomplete/users.json'), {
          params: {
            search: this.search,
            per_page: 20,
            active: true,
            current_user: true,
            project_id: gon.current_project_id,
          },
        })
        .then(({ data }) => {
          this.users = data;
        })
        .catch(() => {
          this.$emit('alert-sidebar-error', this.$options.FETCH_USERS_ERROR);
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
            projectPath: this.projectPath,
          },
        })
        .then(() => {
          this.hideDropdown();
          this.$emit('alert-refresh');
        })
        .catch(() => {
          this.$emit('alert-sidebar-error', this.$options.UPDATE_ALERT_ASSIGNEES_ERROR);
        })
        .finally(() => {
          this.isUpdating = false;
        });
    },
  },
};
</script>

<template>
  <div class="block alert-status">
    <div ref="status" class="sidebar-collapsed-icon" @click="$emit('toggle-sidebar')">
      <gl-icon name="user" :size="14" />
      <gl-loading-icon v-if="isUpdating" />
      <p v-else class="collapse-truncated-title px-1">{{ assignedUsers }}</p>
    </div>
    <gl-tooltip :target="() => $refs.status" boundary="viewport" placement="left">
      <gl-sprintf :message="s__('AlertManagement|Alert assignee(s): %{assignees}')">
        <template #assignees>
          {{ assignedUsers }}
        </template>
      </gl-sprintf>
    </gl-tooltip>

    <div class="hide-collapsed">
      <p class="title gl-display-flex gl-justify-content-space-between">
        {{ s__('AlertManagement|Assignee') }}
        <a
          v-if="isEditable"
          ref="editButton"
          class="btn-link"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ s__('AlertManagement|Edit') }}
        </a>
      </p>

      <div class="dropdown dropdown-menu-selectable" :class="dropdownClass">
        <gl-dropdown
          ref="dropdown"
          :text="assignedUsers"
          class="w-100"
          toggle-class="dropdown-menu-toggle"
          variant="outline-default"
          @keydown.esc.native="hideDropdown"
          @hide="hideDropdown"
        >
          <div class="dropdown-title">
            <span class="alert-title">{{ s__('AlertManagement|Assign Assignees') }}</span>
            <gl-button
              :aria-label="__('Close')"
              variant="link"
              class="dropdown-title-button dropdown-menu-close"
              icon="close"
              @click="hideDropdown"
            />
          </div>
          <div class="dropdown-input">
            <input
              v-model.trim="search"
              class="dropdown-input-field"
              type="search"
              :placeholder="__('Search users')"
            />
            <gl-icon name="search" class="dropdown-input-search ic-search" data-hidden="true" />
          </div>
          <div class="dropdown-content dropdown-body">
            <template v-if="userListValid">
              <gl-dropdown-item @click="updateAlertAssignees('')">
                {{ s__('AlertManagement|Unassigned') }}
              </gl-dropdown-item>
              <gl-dropdown-divider />

              <gl-dropdown-header class="mt-0">
                {{ s__('AlertManagement|Assignee(s)') }}
              </gl-dropdown-header>

              <template v-for="user in users">
                <sidebar-assignee
                  v-if="isActive(user.username)"
                  :key="user.username"
                  :user="user"
                  :active="true"
                  @update-alert-assignees="updateAlertAssignees"
                />
              </template>
              <gl-dropdown-divider />
              <template v-for="user in users">
                <sidebar-assignee
                  v-if="!isActive(user.username)"
                  :key="user.username"
                  :user="user"
                  :active="false"
                  @update-alert-assignees="updateAlertAssignees"
                />
              </template>
            </template>
            <gl-dropdown-item v-else-if="userListEmpty">
              {{ s__('AlertManagement|No Matching Results') }}
            </gl-dropdown-item>
            <gl-loading-icon v-else />
          </div>
        </gl-dropdown>
      </div>

      <gl-loading-icon v-if="isUpdating" :inline="true" />
      <p
        v-else-if="!isDropdownShowing"
        class="value gl-m-0"
        :class="{ 'no-value': !alert.assignees.nodes }"
      >
        <span v-if="alert.assignees.nodes" class="gl-text-gray-700" data-testid="assigned-users">{{
          assignedUsers
        }}</span>
        <span v-else>
          {{ s__('AlertManagement|None') }}
        </span>
      </p>
    </div>
  </div>
</template>
