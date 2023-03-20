<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlAvatar,
  GlSprintf,
} from '@gitlab/ui';
import { debounce, intersectionWith, groupBy, differenceBy, intersectionBy } from 'lodash';
import { createAlert } from '~/alert';
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
    label: {
      type: String,
      required: false,
      default: i18n.selectUsers,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    preselectedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      loading: false,
      initialLoading: false,
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
    preselected() {
      return groupBy(this.preselectedItems, 'type');
    },
    showDeployKeys() {
      return (
        (this.accessLevel === ACCESS_LEVELS.PUSH || this.accessLevel === ACCESS_LEVELS.CREATE) &&
        this.deployKeys.length
      );
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

      return labelPieces.join(', ') || this.label;
    },
    toggleClass() {
      return this.toggleLabel === this.label ? 'gl-text-gray-500!' : '';
    },
    selection() {
      return [
        ...this.getDataForSave(LEVEL_TYPES.ROLE, 'access_level'),
        ...this.getDataForSave(LEVEL_TYPES.GROUP, 'group_id'),
        ...this.getDataForSave(LEVEL_TYPES.USER, 'user_id'),
        ...this.getDataForSave(LEVEL_TYPES.DEPLOY_KEY, 'deploy_key_id'),
      ];
    },
  },
  watch: {
    query: debounce(function debouncedSearch() {
      return this.getData();
    }, 500),
  },
  created() {
    this.getData({ initial: true });
  },
  methods: {
    focusInput() {
      this.$refs.search.focusInput();
    },
    getData({ initial = false } = {}) {
      this.initialLoading = initial;
      this.loading = true;

      if (this.hasLicense) {
        Promise.all([
          getDeployKeys(this.query),
          getUsers(this.query),
          this.groups.length ? Promise.resolve({ data: this.groups }) : getGroups(),
        ])
          .then(([deployKeysResponse, usersResponse, groupsResponse]) => {
            this.consolidateData(deployKeysResponse.data, usersResponse.data, groupsResponse.data);
            this.setSelected({ initial });
          })
          .catch(() =>
            createAlert({ message: __('Failed to load groups, users and deploy keys.') }),
          )
          .finally(() => {
            this.initialLoading = false;
            this.loading = false;
          });
      } else {
        getDeployKeys(this.query)
          .then((deployKeysResponse) => {
            this.consolidateData(deployKeysResponse.data);
            this.setSelected({ initial });
          })
          .catch(() => createAlert({ message: __('Failed to load deploy keys.') }))
          .finally(() => {
            this.initialLoading = false;
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
        this.users = usersResponse.map(({ id, name, username, avatar_url }) => ({
          id,
          name,
          username,
          avatar_url,
          type: LEVEL_TYPES.USER,
        }));
      }

      this.deployKeys = deployKeysResponse.map((response) => {
        const {
          id,
          fingerprint,
          fingerprint_sha256: fingerprintSha256,
          title,
          owner: { avatar_url, name, username },
        } = response;

        const availableFingerprint = fingerprintSha256 || fingerprint;
        const shortFingerprint = `(${availableFingerprint.substring(0, 14)}...)`;

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
    setSelected({ initial } = {}) {
      if (initial) {
        // as all available groups && roles are always visible in the dropdown, we set local selected by looking
        // for intersection in all roles/groups and initial selected (returned from BE).
        // It is different for the users - not all the users will be returned on the first data load (another set
        // will be returned on search, only first 20 are displayed initially).
        // That is why we set ALL initial selected users (returned from BE) as local selected (not looking
        // for the intersection with all users  data) and later if the selected happens to be in the users list
        // we filter it out from the list so that not to have duplicates
        // TODO: we'll need to get back to how to handle deploy keys here but they are out of scope
        // and will be checked when migrating protected branches access dropdown to the current component
        // related issue - https://gitlab.com/gitlab-org/gitlab/-/issues/284784
        const selectedRoles = intersectionWith(
          this.roles,
          this.preselectedItems,
          (role, selected) => {
            return selected.type === LEVEL_TYPES.ROLE && role.id === selected.access_level;
          },
        );
        this.selected[LEVEL_TYPES.ROLE] = selectedRoles;

        const selectedGroups = intersectionWith(
          this.groups,
          this.preselectedItems,
          (group, selected) => {
            return selected.type === LEVEL_TYPES.GROUP && group.id === selected.group_id;
          },
        );
        this.selected[LEVEL_TYPES.GROUP] = selectedGroups;

        const selectedDeployKeys = intersectionWith(
          this.deployKeys,
          this.preselectedItems,
          (key, selected) => {
            return selected.type === LEVEL_TYPES.DEPLOY_KEY && key.id === selected.deploy_key_id;
          },
        );
        this.selected[LEVEL_TYPES.DEPLOY_KEY] = selectedDeployKeys;

        const selectedUsers = this.preselectedItems
          .filter(({ type }) => type === LEVEL_TYPES.USER)
          .map(({ user_id: id, name, username, avatar_url, type }) => ({
            id,
            name,
            username,
            avatar_url,
            type,
          }));

        this.selected[LEVEL_TYPES.USER] = selectedUsers;
      }

      this.users = this.users.filter(
        (user) => !this.selected[LEVEL_TYPES.USER].some((selected) => selected.id === user.id),
      );
      this.users.unshift(...this.selected[LEVEL_TYPES.USER]);
    },
    getDataForSave(accessType, key) {
      const selected = this.selected[accessType].map(({ id }) => ({ [key]: id }));
      const preselected = this.preselected[accessType];
      const added = differenceBy(selected, preselected, key);
      const preserved = intersectionBy(preselected, selected, key).map(({ id, [key]: keyId }) => ({
        id,
        [key]: keyId,
      }));
      const removed = differenceBy(preselected, selected, key).map(({ id, [key]: keyId }) => ({
        id,
        [key]: keyId,
        _destroy: true,
      }));
      return [...added, ...removed, ...preserved];
    },
    onItemClick(item) {
      this.toggleSelection(this.selected[item.type], item);
      this.emitUpdate();
    },
    toggleSelection(arr, item) {
      const itemIndex = arr.findIndex(({ id }) => id === item.id);
      if (itemIndex > -1) {
        arr.splice(itemIndex, 1);
      } else arr.push(item);
    },
    isSelected(item) {
      return this.selected[item.type].some((selected) => selected.id === item.id);
    },
    emitUpdate() {
      this.$emit('select', this.selection);
    },
    onHide() {
      this.$emit('hidden', this.selection);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :disabled="disabled || initialLoading"
    :text="toggleLabel"
    class="gl-min-w-20"
    :toggle-class="toggleClass"
    aria-labelledby="allowed-users-label"
    @shown="focusInput"
    @hidden="onHide"
  >
    <template #header>
      <gl-search-box-by-type ref="search" v-model.trim="query" :is-loading="loading" />
    </template>
    <template v-if="roles.length">
      <gl-dropdown-section-header>{{
        $options.i18n.rolesSectionHeader
      }}</gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="role in roles"
        :key="`${role.id}${role.text}`"
        data-testid="role-dropdown-item"
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
        :key="`${group.id}${group.name}`"
        data-testid="group-dropdown-item"
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
        :key="`${user.id}${user.username}`"
        data-testid="user-dropdown-item"
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
        :key="`${key.id}-{key.title}`"
        data-testid="deploy_key-dropdown-item"
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
