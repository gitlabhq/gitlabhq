<script>
import {
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapActions } from 'vuex';
import { getLocationHash, doesHashExistInUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  DISCUSSION_FILTERS_DEFAULT_VALUE,
  HISTORY_ONLY_FILTER_VALUE,
  COMMENTS_ONLY_FILTER_VALUE,
  DISCUSSION_TAB_LABEL,
  DISCUSSION_FILTER_TYPES,
  NOTE_UNDERSCORE,
  ASC,
  DESC,
} from '../constants';
import notesEventHub from '../event_hub';

const SORT_OPTIONS = [
  { key: DESC, text: __('Newest first'), cls: 'js-newest-first' },
  { key: ASC, text: __('Oldest first'), cls: 'js-oldest-first' },
];

export default {
  SORT_OPTIONS,
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    LocalStorageSync,
  },
  mixins: [Tracking.mixin()],
  props: {
    filters: {
      type: Array,
      required: true,
    },
    selectedValue: {
      type: Number,
      default: DISCUSSION_FILTERS_DEFAULT_VALUE,
      required: false,
    },
  },
  data() {
    return {
      currentValue: doesHashExistInUrl(NOTE_UNDERSCORE)
        ? DISCUSSION_FILTERS_DEFAULT_VALUE
        : this.selectedValue,
      defaultValue: DISCUSSION_FILTERS_DEFAULT_VALUE,
      displayFilters: true,
    };
  },
  computed: {
    ...mapGetters([
      'getNotesDataByProp',
      'timelineEnabled',
      'isLoading',
      'sortDirection',
      'persistSortOrder',
      'noteableType',
    ]),
    currentFilter() {
      if (!this.currentValue) return this.filters[0];
      return this.filters.find((filter) => filter.value === this.currentValue);
    },
    selectedSortOption() {
      return SORT_OPTIONS.find(({ key }) => this.sortDirection === key);
    },
    sortStorageKey() {
      return `sort_direction_${this.noteableType.toLowerCase()}`;
    },
  },
  created() {
    if (window.mrTabs) {
      const { eventHub, currentTab } = window.mrTabs;

      eventHub.$on('MergeRequestTabChange', this.toggleFilters);
      this.toggleFilters(currentTab);
    }

    notesEventHub.$on('dropdownSelect', this.selectFilter);
    window.addEventListener('hashchange', this.handleLocationHash);
  },
  mounted() {
    this.toggleCommentsForm();
  },
  destroyed() {
    notesEventHub.$off('dropdownSelect', this.selectFilter);
    window.removeEventListener('hashchange', this.handleLocationHash);
  },
  methods: {
    ...mapActions([
      'filterDiscussion',
      'setCommentsDisabled',
      'setTargetNoteHash',
      'setTimelineView',
      'setDiscussionSortDirection',
    ]),
    selectFilter(value, persistFilter = true) {
      const filter = parseInt(value, 10);

      if (filter === this.currentValue) return;

      if (this.timelineEnabled && filter !== COMMENTS_ONLY_FILTER_VALUE) {
        this.setTimelineView(false);
      }
      this.currentValue = filter;
      this.filterDiscussion({
        path: this.getNotesDataByProp('discussionsPath'),
        filter,
        persistFilter,
      });
      this.toggleCommentsForm();
    },
    toggleCommentsForm() {
      this.setCommentsDisabled(this.currentValue === HISTORY_ONLY_FILTER_VALUE);
    },
    toggleFilters(tab) {
      this.displayFilters = tab === DISCUSSION_TAB_LABEL;
    },
    handleLocationHash() {
      const hash = getLocationHash();

      if (/^note_/.test(hash) && this.currentValue !== DISCUSSION_FILTERS_DEFAULT_VALUE) {
        this.selectFilter(this.defaultValue, false);
        this.setTargetNoteHash(hash);
      }
    },
    filterType(value) {
      if (value === 0) {
        return DISCUSSION_FILTER_TYPES.ALL;
      }
      if (value === 1) {
        return DISCUSSION_FILTER_TYPES.COMMENTS;
      }
      return DISCUSSION_FILTER_TYPES.HISTORY;
    },
    fetchSortedDiscussions(direction) {
      if (this.isSortDropdownItemActive(direction)) {
        return;
      }

      this.setDiscussionSortDirection({ direction });
      this.track('change_discussion_sort_direction', { property: direction });
    },
    isSortDropdownItemActive(sortDir) {
      return sortDir === this.sortDirection;
    },
  },
};
</script>

<template>
  <div
    v-if="displayFilters"
    id="discussion-preferences"
    data-testid="discussion-preferences"
    class="full-width-mobile gl-inline-block gl-align-bottom"
  >
    <local-storage-sync
      :value="sortDirection"
      :storage-key="sortStorageKey"
      :persist="persistSortOrder"
      as-string
      @input="setDiscussionSortDirection({ direction: $event })"
    />
    <gl-disclosure-dropdown
      id="discussion-preferences-dropdown"
      class="full-width-mobile"
      data-testid="discussion-preferences-dropdown"
      :toggle-text="__('Sort or filter')"
      :disabled="isLoading"
      placement="bottom-end"
    >
      <gl-disclosure-dropdown-group id="discussion-sort">
        <gl-disclosure-dropdown-item
          v-for="{ text, key, cls } in $options.SORT_OPTIONS"
          :key="text"
          :class="cls"
          :is-selected="isSortDropdownItemActive(key)"
          @action="fetchSortedDiscussions(key)"
        >
          <template #list-item>
            <gl-icon
              name="mobile-issue-close"
              data-testid="dropdown-item-checkbox"
              :class="[
                'gl-new-dropdown-item-check-icon',
                { 'gl-invisible': !isSortDropdownItemActive(key) },
              ]"
            />
            {{ text }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
      <gl-disclosure-dropdown-group
        id="discussion-filter"
        class="discussion-filter-container js-discussion-filter-container"
        bordered
      >
        <gl-disclosure-dropdown-item
          v-for="filter in filters"
          :key="filter.value"
          :is-selected="filter.value === currentValue"
          :class="{ 'is-active': filter.value === currentValue }"
          :data-filter-type="filterType(filter.value)"
          data-testid="filter-menu-item"
          @action="selectFilter(filter.value)"
        >
          <template #list-item>
            <gl-icon
              name="mobile-issue-close"
              data-testid="dropdown-item-checkbox"
              :class="[
                'gl-new-dropdown-item-check-icon',
                { 'gl-invisible': filter.value !== currentValue },
              ]"
            />
            {{ filter.title }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
  </div>
</template>
