<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { ASC, DESC } from '../constants';

const SORT_OPTIONS = [
  { key: DESC, text: __('Newest first'), cls: 'js-newest-first' },
  { key: ASC, text: __('Oldest first'), cls: 'js-oldest-first' },
];

export default {
  SORT_OPTIONS,
  components: {
    GlDropdown,
    GlDropdownItem,
    LocalStorageSync,
  },
  mixins: [Tracking.mixin()],
  computed: {
    ...mapGetters(['sortDirection', 'persistSortOrder', 'noteableType']),
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

      this.setDiscussionSortDirection({ direction });
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
    class="gl-mr-3 gl-display-inline-block gl-vertical-align-bottom full-width-mobile"
  >
    <local-storage-sync
      :value="sortDirection"
      :storage-key="storageKey"
      :persist="persistSortOrder"
      @input="setDiscussionSortDirection({ direction: $event })"
    />
    <gl-dropdown :text="dropdownText" class="js-dropdown-text full-width-mobile">
      <gl-dropdown-item
        v-for="{ text, key, cls } in $options.SORT_OPTIONS"
        :key="key"
        :class="cls"
        :is-check-item="true"
        :is-checked="isDropdownItemActive(key)"
        @click="fetchSortedDiscussions(key)"
      >
        {{ text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
