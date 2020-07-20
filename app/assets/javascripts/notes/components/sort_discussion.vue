gs
<script>
import { GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import Tracking from '~/tracking';
import { ASC, DESC } from '../constants';

const SORT_OPTIONS = [
  { key: DESC, text: __('Newest first'), cls: 'js-newest-first' },
  { key: ASC, text: __('Oldest first'), cls: 'js-oldest-first' },
];

export default {
  SORT_OPTIONS,
  components: {
    GlIcon,
    LocalStorageSync,
  },
  mixins: [Tracking.mixin()],
  computed: {
    ...mapGetters(['sortDirection', 'noteableType']),
    selectedOption() {
      return SORT_OPTIONS.find(({ key }) => this.sortDirection === key);
    },
    dropdownText() {
      return this.selectedOption.text;
    },
    storageKey() {
      return `sort_direction_${this.noteableType.toLowerCase()}`;
    },
  },
  methods: {
    ...mapActions(['setDiscussionSortDirection']),
    fetchSortedDiscussions(direction) {
      if (this.isDropdownItemActive(direction)) {
        return;
      }

      this.setDiscussionSortDirection(direction);
      this.track('change_discussion_sort_direction', { property: direction });
    },
    isDropdownItemActive(sortDir) {
      return sortDir === this.sortDirection;
    },
  },
};
</script>

<template>
  <div
    data-testid="sort-discussion-filter"
    class="gl-mr-2 gl-display-inline-block gl-vertical-align-bottom full-width-mobile"
  >
    <local-storage-sync
      :value="sortDirection"
      :storage-key="storageKey"
      @input="setDiscussionSortDirection"
    />
    <button class="btn btn-sm js-dropdown-text" data-toggle="dropdown" aria-expanded="false">
      {{ dropdownText }}
      <gl-icon name="chevron-down" />
    </button>
    <div ref="dropdownMenu" class="dropdown-menu dropdown-menu-selectable dropdown-menu-right">
      <div class="dropdown-content">
        <ul>
          <li v-for="{ text, key, cls } in $options.SORT_OPTIONS" :key="key">
            <button
              :class="[cls, { 'is-active': isDropdownItemActive(key) }]"
              type="button"
              @click="fetchSortedDiscussions(key)"
            >
              {{ text }}
            </button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
