<script>
import { GlDropdown, GlDropdownItem, GlDropdownText, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from '~/api';
import { s__ } from '~/locale';
import { SEARCH_DELAY } from '../constants';

export default {
  name: 'GroupSelect',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlSearchBoxByType,
  },
  model: {
    prop: 'selectedGroup',
  },
  data() {
    return {
      isFetching: false,
      groups: [],
      selectedGroup: {},
      searchTerm: '',
    };
  },
  computed: {
    selectedGroupName() {
      return this.selectedGroup.name || this.$options.i18n.dropdownText;
    },
    isFetchResultEmpty() {
      return this.groups.length === 0;
    },
  },
  watch: {
    searchTerm() {
      this.retrieveGroups();
    },
  },
  mounted() {
    this.retrieveGroups();
  },
  methods: {
    retrieveGroups: debounce(function debouncedRetrieveGroups() {
      this.isFetching = true;
      return Api.groups(this.searchTerm, this.$options.defaultFetchOptions)
        .then((response) => {
          this.groups = response.map((group) => ({
            id: group.id,
            name: group.full_name,
            path: group.path,
          }));
          this.isFetching = false;
        })
        .catch(() => {
          this.isFetching = false;
        });
    }, SEARCH_DELAY),
    selectGroup(group) {
      this.selectedGroup = group;

      this.$emit('input', this.selectedGroup);
    },
  },
  i18n: {
    dropdownText: s__('GroupSelect|Select a group'),
    searchPlaceholder: s__('GroupSelect|Search groups'),
    emptySearchResult: s__('GroupSelect|No matching results'),
  },
  defaultFetchOptions: {
    exclude_internal: true,
    active: true,
  },
};
</script>
<template>
  <div>
    <gl-dropdown
      data-testid="group-select-dropdown"
      :text="selectedGroupName"
      block
      menu-class="gl-w-full!"
    >
      <gl-search-box-by-type
        v-model.trim="searchTerm"
        :is-loading="isFetching"
        :placeholder="$options.i18n.searchPlaceholder"
        data-qa-selector="group_select_dropdown_search_field"
      />
      <gl-dropdown-item
        v-for="group in groups"
        :key="group.id"
        :name="group.name"
        @click="selectGroup(group)"
      >
        {{ group.name }}
      </gl-dropdown-item>
      <gl-dropdown-text v-if="isFetchResultEmpty && !isFetching" data-testid="empty-result-message">
        <span class="gl-text-gray-500">{{ $options.i18n.emptySearchResult }}</span>
      </gl-dropdown-text>
    </gl-dropdown>
  </div>
</template>
