<script>
import { GlCollapsibleListbox, GlButton, GlIcon, GlSprintf, GlButtonGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { InternalEvents } from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { __ } from '~/locale';
import { MR_FILTER_OPTIONS, MR_FILTER_TRACKING_OPENED } from '~/notes/constants';

export default {
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlButtonGroup,
    GlIcon,
    GlSprintf,
    LocalStorageSync,
  },
  mixins: [InternalEvents.mixin()],
  data() {
    return {
      selectedFilters: MR_FILTER_OPTIONS.map((f) => f.value),
    };
  },
  computed: {
    ...mapState({
      mergeRequestFilters: (state) => state.notes.mergeRequestFilters,
      discussionSortOrder: (state) => state.notes.discussionSortOrder,
    }),
    selectedFilterText() {
      const { length } = this.mergeRequestFilters;

      if (length === 0) return __('None');

      const firstSelected = MR_FILTER_OPTIONS.find(
        ({ value }) => this.mergeRequestFilters[0] === value,
      );

      if (length === MR_FILTER_OPTIONS.length) {
        return __('All activity');
      }
      if (length > 1) {
        return `%{strongStart}${firstSelected.text}%{strongEnd} +${length - 1} more`;
      }

      return firstSelected.text;
    },
    isSortAsc() {
      return this.discussionSortOrder === 'asc';
    },
    sortIcon() {
      return this.isSortAsc ? 'sort-lowest' : 'sort-highest';
    },
  },
  methods: {
    ...mapActions(['updateMergeRequestFilters', 'setDiscussionSortDirection']),
    updateSortDirection() {
      this.setDiscussionSortDirection({
        direction: this.isSortAsc ? 'desc' : 'asc',
      });
    },
    filterListShown() {
      this.trackEvent(MR_FILTER_TRACKING_OPENED);
    },
    applyFilters() {
      this.updateMergeRequestFilters(this.selectedFilters);
    },
    localSyncFilters(filters) {
      this.updateMergeRequestFilters(filters);
      this.selectedFilters = filters;
    },
    deselectAll() {
      this.selectedFilters = [];
    },
    selectAll() {
      this.selectedFilters = MR_FILTER_OPTIONS.map((f) => f.value);
    },
  },
  MR_FILTER_OPTIONS,
};
</script>

<template>
  <div>
    <local-storage-sync
      :value="discussionSortOrder"
      storage-key="sort_direction_merge_request"
      as-string
      @input="setDiscussionSortDirection({ direction: $event })"
    />
    <local-storage-sync
      :value="mergeRequestFilters"
      storage-key="mr_activity_filters_2"
      @input="localSyncFilters"
    />
    <gl-button-group>
      <gl-collapsible-listbox
        v-model="selectedFilters"
        :items="$options.MR_FILTER_OPTIONS"
        :header-text="__('Filter activity')"
        :show-select-all-button-label="__('Select all')"
        :reset-button-label="__('Deselect all')"
        multiple
        placement="right"
        @shown="filterListShown"
        @hidden="applyFilters"
        @reset="deselectAll"
        @select-all="selectAll"
      >
        <template #toggle>
          <gl-button class="gl-rounded-top-right-none! gl-rounded-bottom-right-none!">
            <gl-sprintf :message="selectedFilterText">
              <template #strong="{ content }">
                <strong>{{ content }}</strong>
              </template>
            </gl-sprintf>
            <gl-icon name="chevron-down" />
          </gl-button>
        </template>
        <template #list-item="{ item }">
          <strong v-if="item.value === '*'">{{ item.text }}</strong>
          <span v-else>{{ item.text }}</span>
        </template>
      </gl-collapsible-listbox>
      <gl-button :icon="sortIcon" @click="updateSortDirection" />
    </gl-button-group>
  </div>
</template>
