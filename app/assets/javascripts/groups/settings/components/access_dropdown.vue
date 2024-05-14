<script>
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';
import { debounce, intersectionWith, groupBy, differenceBy, intersectionBy } from 'lodash';
import { createAlert } from '~/alert';
import { __, s__, n__ } from '~/locale';
import { getSubGroups } from '../api/access_dropdown_api';
import { LEVEL_TYPES } from '../constants';

export const i18n = {
  selectUsers: s__('ProtectedEnvironment|Select groups'),
  groupsSectionHeader: s__('AccessDropdown|Groups'),
};

export default {
  i18n,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
  },
  props: {
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
      groups: [],
      selected: {
        [LEVEL_TYPES.GROUP]: [],
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

      const labelPieces = [];

      if (counts[LEVEL_TYPES.GROUP] > 0) {
        labelPieces.push(n__('1 group', '%d groups', counts[LEVEL_TYPES.GROUP]));
      }

      return labelPieces.join(', ') || this.label;
    },
    toggleClass() {
      return this.toggleLabel === this.label ? 'gl-text-gray-500!' : '';
    },
    selection() {
      return [...this.getDataForSave(LEVEL_TYPES.GROUP, 'group_id')];
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
          getSubGroups({
            includeParentDescendants: true,
            includeParentSharedGroups: true,
            search: this.query,
          }),
        ])
          .then(([groupsResponse]) => {
            this.consolidateData(groupsResponse.data);
            this.setSelected({ initial });
          })
          .catch(() => createAlert({ message: __('Failed to load groups.') }))
          .finally(() => {
            this.initialLoading = false;
            this.loading = false;
          });
      }
    },
    consolidateData(groupsResponse = []) {
      if (this.hasLicense) {
        this.groups = groupsResponse.map((group) => ({ ...group, type: LEVEL_TYPES.GROUP }));
      }
    },
    setSelected({ initial } = {}) {
      if (initial) {
        const selectedGroups = intersectionWith(
          this.groups,
          this.preselectedItems,
          (group, selected) => {
            return selected.type === LEVEL_TYPES.GROUP && group.id === selected.group_id;
          },
        );
        this.selected[LEVEL_TYPES.GROUP] = selectedGroups;
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
    <div>
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
          @click.native.capture.stop="onItemClick(group)"
        >
          {{ group.name }}
        </gl-dropdown-item>
      </template>
    </div>
  </gl-dropdown>
</template>
