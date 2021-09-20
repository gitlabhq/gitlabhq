<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlAvatar,
  GlSprintf,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import { __, s__, n__ } from '~/locale';
import { getUsers, getGroups, getDeployKeys } from '../api/access_dropdown_api';
import { LEVEL_TYPES, ACCESS_LEVELS } from '../constants';

export const i18n = {
  selectUsers: s__('ProtectedEnvironment|Select users'),
  rolesSectionHeader: s__('AccessDropdown|Roles'),
  groupsSectionHeader: s__('AccessDropdown|Groups'),
  usersSectionHeader: s__('AccessDropdown|Users'),
  deployKeysSectionHeader: s__('AccessDropdown|Deploy Keys'),
  ownedBy: __('Owned by %{image_tag}'),
};

export default {
  i18n,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlLoadingIcon,
    GlAvatar,
    GlSprintf,
  },
  props: {
    accessLevelsData: {
      type: Array,
      required: true,
    },
    accessLevel: {
      required: true,
      type: String,
    },
    hasLicense: {
      required: false,
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      loading: false,
      query: '',
      users: [],
      groups: [],
      roles: [],
      deployKeys: [],
      selected: {
        [LEVEL_TYPES.GROUP]: [],
        [LEVEL_TYPES.USER]: [],
        [LEVEL_TYPES.ROLE]: [],
        [LEVEL_TYPES.DEPLOY_KEY]: [],
      },
    };
  },
  computed: {
    showDeployKeys() {
      return this.accessLevel === ACCESS_LEVELS.PUSH && this.deployKeys.length;
    },
    toggleLabel() {
      const counts = Object.entries(this.selected).reduce((acc, [key, value]) => {
        acc[key] = value.length;
        return acc;
      }, {});

      const isOnlyRoleSelected =
        counts[LEVEL_TYPES.ROLE] === 1 &&
        [counts[LEVEL_TYPES.USER], counts[LEVEL_TYPES.GROUP], counts[LEVEL_TYPES.DEPLOY_KEY]].every(
          (count) => count === 0,
        );

      if (isOnlyRoleSelected) {
        return this.selected[LEVEL_TYPES.ROLE][0].text;
      }

      const labelPieces = [];

      if (counts[LEVEL_TYPES.ROLE] > 0) {
        labelPieces.push(n__('1 role', '%d roles', counts[LEVEL_TYPES.ROLE]));
      }

      if (counts[LEVEL_TYPES.USER] > 0) {
        labelPieces.push(n__('1 user', '%d users', counts[LEVEL_TYPES.USER]));
      }

      if (counts[LEVEL_TYPES.DEPLOY_KEY] > 0) {
        labelPieces.push(n__('1 deploy key', '%d deploy keys', counts[LEVEL_TYPES.DEPLOY_KEY]));
      }

      if (counts[LEVEL_TYPES.GROUP] > 0) {
        labelPieces.push(n__('1 group', '%d groups', counts[LEVEL_TYPES.GROUP]));
      }

      return labelPieces.join(', ') || i18n.selectUsers;
    },
    toggleClass() {
      return this.toggleLabel === i18n.selectUsers ? 'gl-text-gray-500!' : '';
    },
  },
  watch: {
    query: debounce(function debouncedSearch() {
      return this.getData();
    }, 500),
  },
  created() {
    this.getData();
  },

  methods: {
    focusInput() {
      this.$refs.search.focusInput();
    },
    getData() {
      this.loading = true;

      if (this.hasLicense) {
        Promise.all([
          getDeployKeys(this.query),
          getUsers(this.query),
          this.groups.length ? Promise.resolve({ data: this.groups }) : getGroups(),
        ])
          .then(([deployKeysResponse, usersResponse, groupsResponse]) =>
            this.consolidateData(deployKeysResponse.data, usersResponse.data, groupsResponse.data),
          )
          .catch(() =>
            createFlash({ message: __('Failed to load groups, users and deploy keys.') }),
          )
          .finally(() => {
            this.loading = false;
          });
      } else {
        getDeployKeys(this.query)
          .then((deployKeysResponse) => this.consolidateData(deployKeysResponse.data))
          .catch(() => createFlash({ message: __('Failed to load deploy keys.') }))
          .finally(() => {
            this.loading = false;
          });
      }
    },
    consolidateData(deployKeysResponse, usersResponse = [], groupsResponse = []) {
      // This re-assignment is intentional as level.type property is being used for comparision,
      // and accessLevelsData is provided by gon.create_access_levels which doesn't have `type` included.
      // See this discussion https://gitlab.com/gitlab-org/gitlab/merge_requests/1629#note_31285823
      this.roles = this.accessLevelsData.map((role) => ({ ...role, type: LEVEL_TYPES.ROLE }));

      if (this.hasLicense) {
        this.groups = groupsResponse.map((group) => ({ ...group, type: LEVEL_TYPES.GROUP }));
        this.users = usersResponse.map((user) => ({ ...user, type: LEVEL_TYPES.USER }));
      }

      this.deployKeys = deployKeysResponse.map((response) => {
        const {
          id,
          fingerprint,
          title,
          owner: { avatar_url, name, username },
        } = response;

        const shortFingerprint = `(${fingerprint.substring(0, 14)}...)`;

        return {
          id,
          title: title.concat(' ', shortFingerprint),
          avatar_url,
          fullname: name,
          username,
          type: LEVEL_TYPES.DEPLOY_KEY,
        };
      });
    },
    onItemClick(item) {
      this.toggleSelection(this.selected[item.type], item);
      this.emitUpdate();
    },
    toggleSelection(arr, item) {
      const itemIndex = arr.indexOf(item);
      if (itemIndex > -1) {
        arr.splice(itemIndex, 1);
      } else arr.push(item);
    },
    isSelected(item) {
      return this.selected[item.type].some((selected) => selected.id === item.id);
    },
    emitUpdate() {
      const selected = Object.values(this.selected).flat();
      this.$emit('select', selected);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :text="toggleLabel"
    class="gl-display-block"
    :toggle-class="toggleClass"
    aria-labelledby="allowed-users-label"
    @shown="focusInput"
  >
    <template #header>
      <gl-search-box-by-type ref="search" v-model.trim="query" />
      <gl-loading-icon v-if="loading" size="sm" />
    </template>
    <template v-if="roles.length">
      <gl-dropdown-section-header>{{
        $options.i18n.rolesSectionHeader
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="role in roles"
        :key="role.id"
        is-check-item
        :is-checked="isSelected(role)"
        @click.native.capture.stop="onItemClick(role)"
      >
        {{ role.text }}
      </gl-dropdown-item>
      <gl-dropdown-divider v-if="groups.length || users.length || showDeployKeys" />
    </template>

    <template v-if="groups.length">
      <gl-dropdown-section-header>{{
        $options.i18n.groupsSectionHeader
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="group in groups"
        :key="group.id"
        :avatar-url="group.avatar_url"
        is-check-item
        :is-checked="isSelected(group)"
        @click.native.capture.stop="onItemClick(group)"
      >
        {{ group.name }}
      </gl-dropdown-item>
      <gl-dropdown-divider v-if="users.length || showDeployKeys" />
    </template>

    <template v-if="users.length">
      <gl-dropdown-section-header>{{
        $options.i18n.usersSectionHeader
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="user in users"
        :key="user.id"
        :avatar-url="user.avatar_url"
        :secondary-text="user.username"
        is-check-item
        :is-checked="isSelected(user)"
        @click.native.capture.stop="onItemClick(user)"
      >
        {{ user.name }}
      </gl-dropdown-item>
      <gl-dropdown-divider v-if="showDeployKeys" />
    </template>

    <template v-if="showDeployKeys">
      <gl-dropdown-section-header>{{
        $options.i18n.deployKeysSectionHeader
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="key in deployKeys"
        :key="key.id"
        is-check-item
        :is-checked="isSelected(key)"
        class="gl-text-truncate"
        @click.native.capture.stop="onItemClick(key)"
      >
        <div class="gl-text-truncate gl-font-weight-bold">{{ key.title }}</div>
        <div class="gl-text-gray-700 gl-text-truncate">
          <gl-sprintf :message="$options.i18n.ownedBy">
            <template #image_tag>
              <gl-avatar :src="key.avatar_url" :size="24" />
            </template> </gl-sprintf
          >{{ key.fullname }} ({{ key.username }})
        </div>
      </gl-dropdown-item>
    </template>
  </gl-dropdown>
</template>
