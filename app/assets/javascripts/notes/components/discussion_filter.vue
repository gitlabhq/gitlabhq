<script>
import $ from 'jquery';
import { mapGetters, mapActions } from 'vuex';
import { getLocationHash } from '../../lib/utils/url_utility';
import Icon from '~/vue_shared/components/icon.vue';
import {
  DISCUSSION_FILTERS_DEFAULT_VALUE,
  HISTORY_ONLY_FILTER_VALUE,
  DISCUSSION_TAB_LABEL,
  DISCUSSION_FILTER_TYPES,
} from '../constants';
import notesEventHub from '../event_hub';

export default {
  components: {
    Icon,
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
      currentValue: this.selectedValue,
      defaultValue: DISCUSSION_FILTERS_DEFAULT_VALUE,
      displayFilters: true,
    };
  },
  computed: {
    ...mapGetters(['getNotesDataByProp']),
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
    this.handleLocationHash();
  },
  mounted() {
    this.toggleCommentsForm();
  },
  destroyed() {
    notesEventHub.$off('dropdownSelect', this.selectFilter);
    window.removeEventListener('hashchange', this.handleLocationHash);
  },
  methods: {
    ...mapActions(['filterDiscussion', 'setCommentsDisabled', 'setTargetNoteHash']),
    selectFilter(value) {
      const filter = parseInt(value, 10);

      // close dropdown
      this.toggleDropdown();

      if (filter === this.currentValue) return;
      this.currentValue = filter;
      this.filterDiscussion({ path: this.getNotesDataByProp('discussionsPath'), filter });
      this.toggleCommentsForm();
    },
    toggleDropdown() {
      $(this.$refs.dropdownToggle).dropdown('toggle');
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
        this.selectFilter(this.defaultValue);
        this.toggleDropdown(); // close dropdown
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
  <div
    v-if="displayFilters"
    class="discussion-filter-container js-discussion-filter-container d-inline-block align-bottom full-width-mobile"
  >
    <button
      id="discussion-filter-dropdown"
      ref="dropdownToggle"
      class="btn btn-sm qa-discussion-filter"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      {{ currentFilter.title }} <icon name="chevron-down" />
    </button>
    <div
      ref="dropdownMenu"
      class="dropdown-menu dropdown-menu-selectable dropdown-menu-right"
      aria-labelledby="discussion-filter-dropdown"
    >
      <div class="dropdown-content">
        <ul>
          <li
            v-for="filter in filters"
            :key="filter.value"
            :data-filter-type="filterType(filter.value)"
          >
            <button
              :class="{ 'is-active': filter.value === currentValue }"
              class="qa-filter-options"
              type="button"
              @click="selectFilter(filter.value)"
            >
              {{ filter.title }}
            </button>
            <div v-if="filter.value === defaultValue" class="dropdown-divider"></div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
