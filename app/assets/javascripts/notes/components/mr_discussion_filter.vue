<script>
import {
  GlCollapsibleListbox,
  GlButton,
  GlIcon,
  GlSprintf,
  GlButtonGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { InternalEvents } from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { __ } from '~/locale';
import { SORT_DIRECTION_UI } from '~/search/sort/constants';
import {
  MR_FILTER_OPTIONS,
  MR_FILTER_TRACKING_OPENED,
  MR_FILTER_TRACKING_USER_COMMENTS,
  MR_FILTER_TRACKING_BOT_COMMENTS,
} from '~/notes/constants';

const filterOptionToTrackingEventMap = {
  comments: MR_FILTER_TRACKING_USER_COMMENTS,
  bot_comments: MR_FILTER_TRACKING_BOT_COMMENTS,
};
const allFilters = MR_FILTER_OPTIONS.map((f) => f.value);

export default {
  components: {
    GlCollapsibleListbox,
    GlButton,
    GlButtonGroup,
    GlIcon,
    GlSprintf,
    LocalStorageSync,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  data() {
    return {
      selectedFilters: allFilters,
      previousFilters: allFilters,
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
    sortDirectionData() {
      return this.isSortAsc ? SORT_DIRECTION_UI.asc : SORT_DIRECTION_UI.desc;
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
    trackDropdownSelection(selectedItem) {
      const trackingEvent = filterOptionToTrackingEventMap[selectedItem];

      if (trackingEvent) {
        this.trackEvent(trackingEvent);
      }
    },
    applyFilters() {
      this.updateMergeRequestFilters(this.selectedFilters);
    },
    localSyncFilters(filters) {
      this.updateMergeRequestFilters(filters);
      this.selectedFilters = filters;
      this.previousFilters = filters;
    },
    deselectAll() {
      this.selectedFilters = [];
      this.previousFilters = [];
    },
    selectAll() {
      this.selectedFilters = allFilters;
      this.previousFilters = allFilters;
    },
    select(allSelectedFilters) {
      const removedFilters = this.previousFilters.filter(
        (filterValue) => !allSelectedFilters.includes(filterValue),
      );
      const addedFilters = allSelectedFilters.filter(
        (filterValue) => !this.previousFilters.includes(filterValue),
      );
      const allInteractedItems = removedFilters.concat(addedFilters);

      allInteractedItems.forEach((filterValue) => {
        this.trackDropdownSelection(filterValue);
      });

      this.previousFilters = allSelectedFilters;
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
        placement="bottom-end"
        @shown="filterListShown"
        @hidden="applyFilters"
        @reset="deselectAll"
        @select-all="selectAll"
        @select="select"
      >
        <template #toggle>
          <gl-button class="!gl-rounded-br-none !gl-rounded-tr-none">
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
      <gl-button
        v-gl-tooltip
        data-testid="mr-discussion-sort-direction"
        :aria-label="sortDirectionData.tooltip"
        :title="sortDirectionData.tooltip"
        :icon="sortDirectionData.icon"
        @click="updateSortDirection"
      />
    </gl-button-group>
  </div>
</template>
