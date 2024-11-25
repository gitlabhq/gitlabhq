<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { debounce, intersectionWith, groupBy, differenceBy, intersectionBy } from 'lodash';
import { createAlert } from '~/alert';
import { __, s__, n__ } from '~/locale';
import { getSubGroups, getUsers } from '../api/access_dropdown_api';
import { LEVEL_TYPES } from '../constants';

export const i18n = {
  selectUsers: s__('ProtectedEnvironment|Select groups'),
  rolesSectionHeader: s__('AccessDropdown|Roles'),
  groupsSectionHeader: s__('AccessDropdown|Groups'),
  usersSectionHeader: s__('AccessDropdown|Users'),
};

export default {
  i18n,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
    GlSearchBoxByType,
  },
  props: {
    accessLevelsData: {
      type: Array,
      required: false,
      default: () => [],
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
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    showUsers: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      loading: false,
      initialLoading: false,
      query: '',
      roles: [],
      groups: [],
      users: [],
      selected: {
        [LEVEL_TYPES.ROLE]: [],
        [LEVEL_TYPES.GROUP]: [],
        [LEVEL_TYPES.USER]: [],
      },
    };
  },
  computed: {
    preselected() {
      return groupBy(this.preselectedItems, 'type');
    },
    toggleLabel() {
      const counts = Object.fromEntries(
        Object.entries(this.selected).map(([key, value]) => [key, value.length]),
      );

      const isOnlyRoleSelected =
        counts[LEVEL_TYPES.ROLE] === 1 &&
        [counts[LEVEL_TYPES.GROUP], counts[LEVEL_TYPES.USER]].every((count) => count === 0);

      if (isOnlyRoleSelected) {
        return this.selected[LEVEL_TYPES.ROLE][0].text;
      }

      const labelPieces = [];

      if (counts[LEVEL_TYPES.ROLE] > 0) {
        labelPieces.push(n__('1 role', '%d roles', counts[LEVEL_TYPES.ROLE]));
      }

      if (counts[LEVEL_TYPES.GROUP] > 0) {
        labelPieces.push(n__('1 group', '%d groups', counts[LEVEL_TYPES.GROUP]));
      }

      if (counts[LEVEL_TYPES.USER] > 0) {
        labelPieces.push(n__('1 user', '%d users', counts[LEVEL_TYPES.USER]));
      }

      return labelPieces.join(', ') || this.label;
    },
    toggleClass() {
      return this.toggleLabel === this.label ? '!gl-text-subtle' : '';
    },
    selection() {
      return [
        ...this.getDataForSave(LEVEL_TYPES.ROLE, 'access_level'),
        ...this.getDataForSave(LEVEL_TYPES.GROUP, 'group_id'),
        ...this.getDataForSave(LEVEL_TYPES.USER, 'user_id'),
      ];
    },
  },
  watch: {
    query: debounce(function debouncedSearch() {
      return this.getData();
    }, 500),
    items(items) {
      this.setDataForSave(items);
    },
  },
  created() {
    this.getData({ initial: true });
  },
  methods: {
    setDataForSave(items) {
      this.selected = items.reduce(
        (selected, item) => {
          if (item.group_id) {
            selected[LEVEL_TYPES.GROUP].push({ id: item.group_id, ...item });
          } else if (item.user_id) {
            selected[LEVEL_TYPES.USER].push({ id: item.user_id, ...item });
          } else if (item.access_level) {
            const level = this.accessLevelsData.find(({ id }) => item.access_level === id);
            selected[LEVEL_TYPES.ROLE].push(level);
          }
          return selected;
        },
        {
          [LEVEL_TYPES.GROUP]: [],
          [LEVEL_TYPES.USER]: [],
          [LEVEL_TYPES.ROLE]: [],
        },
      );
    },
    focusInput() {
      this.$refs.search.focusInput();
    },
    getData({ initial = false } = {}) {
      this.initialLoading = initial;
      this.loading = true;

      if (this.hasLicense) {
        Promise.all([
          getSubGroups({
            includeParentDescendants: true,
            includeParentSharedGroups: true,
            search: this.query,
          }),
          this.showUsers ? getUsers(this.query) : Promise.resolve({ data: this.users }),
        ])
          .then(([groupsResponse, usersResponse]) => {
            this.consolidateData(groupsResponse.data, usersResponse.data);
            this.setSelected({ initial });
          })
          .catch(() => createAlert({ message: __('Failed to load groups and users.') }))
          .finally(() => {
            this.initialLoading = false;
            this.loading = false;
          });
      }
    },
    consolidateData(groupsResponse = [], usersResponse = []) {
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
    },
    setSelected({ initial } = {}) {
      if (initial) {
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

        this.users = this.users.filter(
          (user) => !this.selected[LEVEL_TYPES.USER].some((selected) => selected.id === user.id),
        );
        this.users.unshift(...this.selected[LEVEL_TYPES.USER]);
      }
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
      this.toggleSelection(item);
      this.emitUpdate();
    },
    toggleSelection(item) {
      const itemSelected = this.isSelected(item);
      if (itemSelected) {
        this.selected[item.type] = this.selected[item.type].filter(({ id }) => id !== item.id);
        return;
      }
      this.selected[item.type].push(item);
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
    <div>
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
          @click.capture.native.stop="onItemClick(role)"
        >
          {{ role.text }}
        </gl-dropdown-item>
        <gl-dropdown-divider v-if="groups.length || users.length" />
      </template>

      <template v-if="groups.length">
        <gl-dropdown-section-header>{{
          $options.i18n.groupsSectionHeader
        }}</gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="group in groups"
          :key="`${group.id}${group.name}`"
          :avatar-url="group.avatar_url"
          is-check-item
          :is-checked="isSelected(group)"
          @click.capture.native.stop="onItemClick(group)"
        >
          {{ group.name }}
        </gl-dropdown-item>
        <gl-dropdown-divider v-if="users.length" />
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
          @click.capture.native.stop="onItemClick(user)"
        >
          {{ user.name }}
        </gl-dropdown-item>
      </template>
    </div>
  </gl-dropdown>
</template>
