<script>
import { mapGetters, mapActions } from 'vuex';
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { getLocationHash, doesHashExistInUrl } from '../../lib/utils/url_utility';
import {
  DISCUSSION_FILTERS_DEFAULT_VALUE,
  HISTORY_ONLY_FILTER_VALUE,
  COMMENTS_ONLY_FILTER_VALUE,
  DISCUSSION_TAB_LABEL,
  DISCUSSION_FILTER_TYPES,
  NOTE_UNDERSCORE,
} from '../constants';
import notesEventHub from '../event_hub';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
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
    ...mapGetters(['getNotesDataByProp', 'timelineEnabled']),
    currentFilter() {
      if (!this.currentValue) return this.filters[0];
      return this.filters.find(filter => filter.value === this.currentValue);
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
      } else if (value === 1) {
        return DISCUSSION_FILTER_TYPES.COMMENTS;
      }
      return DISCUSSION_FILTER_TYPES.HISTORY;
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="displayFilters"
    id="discussion-filter-dropdown"
    class="gl-mr-3 full-width-mobile discussion-filter-container js-discussion-filter-container"
    data-qa-selector="discussion_filter_dropdown"
    :text="currentFilter.title"
  >
    <div v-for="filter in filters" :key="filter.value" class="dropdown-item-wrapper">
      <gl-dropdown-item
        :is-check-item="true"
        :is-checked="filter.value === currentValue"
        :class="{ 'is-active': filter.value === currentValue }"
        :data-filter-type="filterType(filter.value)"
        data-qa-selector="filter_menu_item"
        @click.prevent="selectFilter(filter.value)"
      >
        {{ filter.title }}
      </gl-dropdown-item>
      <gl-dropdown-divider v-if="filter.value === defaultValue" />
    </div>
  </gl-dropdown>
</template>
