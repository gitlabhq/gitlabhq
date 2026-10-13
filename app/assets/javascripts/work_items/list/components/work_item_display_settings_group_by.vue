<script>
import {
  GlCollapsibleListbox,
  GlIcon,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlToastMixin,
  GlToggle,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import { DRAG_DELAY, defaultSortableOptions } from '~/sortable/constants';
import {
  DEFAULT_GROUP_BY,
  groupingStrategyFor,
  hasDecorationIcon,
  decorationIconStyle,
} from '~/work_items/board/grouping';
import {
  MAX_VISIBLE_GROUPS,
  SHOW_ALL_GROUPS,
  effectiveVisibleGroups,
  exceedsGroupLimit,
  isGroupVisible as computeGroupVisible,
  toggleGroupVisibility as computeToggleGroupVisibility,
} from '~/work_items/board/grouping/visibility';
import {
  GROUP_SORT,
  effectiveGroupSort,
  applyGroupSort,
  reorderGroupIds,
} from '~/work_items/board/grouping/ordering';
import { getGroupId } from '~/work_items/board/grouping/identity';
import { I18N_GROUP_MOVED } from '~/work_items/board/constants';
import { persistMetadataPreference, alertPreferenceError } from '../display_settings_preferences';

export default {
  name: 'WorkItemDisplaySettingsGroupBy',
  components: {
    DraggableCompat,
    GlCollapsibleListbox,
    GlIcon,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlToggle,
  },
  mixins: [InternalEvents.mixin(), GlToastMixin],
  i18n: {
    groupBy: s__('WorkItems|Group by'),
    sort: s__('WorkItems|Sort'),
    ascending: __('Ascending'),
    descending: __('Descending'),
    manual: s__('WorkItems|Manual'),
    groups: s__('WorkItems|Groups'),
    searchPlaceholder: s__('WorkItems|Search groups'),
    shown: s__('WorkItems|Shown'),
    hidden: s__('WorkItems|Hidden'),
    hideAll: s__('WorkItems|Hide all'),
    noGroupsFound: s__('WorkItems|No groups match your search.'),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemTypeId: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: false,
      default: '',
    },
    namespacePreferences: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isSavedView: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['update-settings'],
  GROUP_BY_LABEL_ID: 'work-item-display-settings-group-by-label',
  SORT_LABEL_ID: 'work-item-display-settings-sort-label',
  groupSortableOptions: {
    ...defaultSortableOptions,
    delay: DRAG_DELAY,
    delayOnTouchOnly: true,
  },
  data() {
    return {
      searchQuery: '',
      groupByValues: [],
    };
  },
  computed: {
    groupBy() {
      return DEFAULT_GROUP_BY;
    },
    strategy() {
      return groupingStrategyFor(this.groupBy.property);
    },
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
    visibleGroups() {
      return effectiveVisibleGroups(
        this.namespacePreferences.visibleGroups ?? SHOW_ALL_GROUPS,
        this.groupByValues.length,
      );
    },
    shownCount() {
      return this.visibleGroups === SHOW_ALL_GROUPS
        ? this.groupByValues.length
        : this.visibleGroups.length;
    },
    isAtGroupLimit() {
      return this.shownCount >= MAX_VISIBLE_GROUPS;
    },
    showGroupLimitHint() {
      return exceedsGroupLimit(this.groupByValues.length);
    },
    groupLimitHint() {
      return sprintf(s__('WorkItems|Select up to %{maxGroups} groups.'), {
        maxGroups: MAX_VISIBLE_GROUPS,
      });
    },
    groupByOptions() {
      return [{ text: this.strategy.label, value: this.strategy.property }];
    },
    groupSort() {
      return effectiveGroupSort({
        groupSort: this.namespacePreferences.groupSort,
        groupOrder: this.namespacePreferences.groupOrder,
      });
    },
    isManualSort() {
      return this.groupSort === GROUP_SORT.MANUAL;
    },
    sortByOptions() {
      return [
        { text: this.$options.i18n.ascending, value: GROUP_SORT.ASC },
        { text: this.$options.i18n.descending, value: GROUP_SORT.DESC },
        { text: this.$options.i18n.manual, value: GROUP_SORT.MANUAL },
      ];
    },
    sortToggleText() {
      return this.sortByOptions.find((option) => option.value === this.groupSort).text;
    },
    isSearching() {
      return Boolean(this.searchQuery.trim());
    },
    sortedGroupByValues() {
      return applyGroupSort({
        values: this.groupByValues,
        groupSort: this.groupSort,
        groupOrder: this.namespacePreferences.groupOrder,
        groupBy: this.groupBy,
      });
    },
    currentGroupOrder() {
      return this.sortedGroupByValues.map((value) => getGroupId({ groupBy: this.groupBy, value }));
    },
    filteredGroupByValues() {
      const query = this.searchQuery.trim().toLowerCase();
      if (!query) return this.sortedGroupByValues;
      return this.sortedGroupByValues.filter((value) => value.name.toLowerCase().includes(query));
    },
    decoratedGroupByValues() {
      return this.filteredGroupByValues.map((value) => {
        const decoration = this.strategy.headerDecoration(value);
        return {
          value,
          showIcon: hasDecorationIcon(decoration),
          iconName: decoration.name,
          iconStyle: decorationIconStyle(decoration),
        };
      });
    },
    shownGroups() {
      return this.decoratedGroupByValues.filter((row) => this.isGroupVisible(row.value));
    },
    hiddenGroups() {
      return this.decoratedGroupByValues.filter((row) => !this.isGroupVisible(row.value));
    },
    noGroupsAvailable() {
      return this.isSearching && this.filteredGroupByValues.length === 0;
    },
  },
  apollo: {
    groupByValues() {
      return {
        query: this.strategy.valuesQuery,
        skip() {
          return !this.strategy;
        },
        variables() {
          return { fullPath: this.fullPath };
        },
        update: (data) => this.strategy.extractValues(data),
        error(error) {
          createAlert({
            message: s__('WorkItems|Something went wrong while fetching the groups.'),
            captureError: true,
            error,
          });
        },
      };
    },
  },
  methods: {
    isGroupVisible(value) {
      return computeGroupVisible(this.visibleGroups, this.groupBy, value);
    },
    toggleGroupVisibility(value) {
      const wasVisible = this.isGroupVisible(value);
      const next = computeToggleGroupVisibility({
        visibleGroups: this.visibleGroups,
        groupBy: this.groupBy,
        value,
        allGroups: this.groupByValues,
      });
      this.trackEvent('configure_columns_on_work_item_board', {
        label: wasVisible ? 'hide_group' : 'show_group',
      });
      this.persist({ visibleGroups: next });
    },
    hideAll() {
      this.trackEvent('configure_columns_on_work_item_board', { label: 'hide_all_groups' });
      this.persist({ visibleGroups: [] });
    },
    groupRowKey(row) {
      return row.value.id;
    },
    // Manual starts from the order on screen so the list doesn't jump. Any other sort
    // clears groupOrder rather than keeping a stale order around unused.
    handleSortSelect(groupSort) {
      if (groupSort === this.groupSort) {
        return;
      }
      this.trackEvent('configure_columns_on_work_item_board', {
        label: `sort_groups_${groupSort}`,
      });
      this.persist({
        groupSort,
        groupOrder: groupSort === GROUP_SORT.MANUAL ? this.currentGroupOrder : [],
      });
    },
    async onGroupMove({ oldIndex, newIndex }) {
      if (oldIndex == null || newIndex == null || oldIndex === newIndex) {
        return;
      }

      const visibleValues = this.shownGroups.map((row) => row.value);
      const [moved] = visibleValues.splice(oldIndex, 1);
      visibleValues.splice(newIndex, 0, moved);

      this.trackEvent('configure_columns_on_work_item_board', { label: 'reorder_drawer' });
      const saved = await this.persist({
        groupSort: GROUP_SORT.MANUAL,
        groupOrder: reorderGroupIds({
          visibleValues,
          groupBy: this.groupBy,
          currentOrder: this.currentGroupOrder,
        }),
      });

      if (saved) {
        this.$toast.show(sprintf(I18N_GROUP_MOVED, { groupName: moved.name }, false));
      }
    },
    async persist(partialSettings) {
      const input = { ...this.namespacePreferences, ...partialSettings };

      if (this.isSavedView) {
        this.$emit('update-settings', input);
        return true;
      }

      try {
        await persistMetadataPreference({
          apolloClient: this.$apollo,
          namespace: this.fullPath,
          workItemTypeId: this.workItemTypeId,
          userPreferencesOnly: false,
          displaySettings: input,
          sort: this.sortKey,
        });
        return true;
      } catch (error) {
        alertPreferenceError(error);
        return false;
      }
    },
  },
};
</script>

<template>
  <div data-testid="display-settings-group-by" class="gl-flex gl-h-full gl-flex-col gl-p-5">
    <div class="gl-mb-4 gl-flex gl-items-center gl-justify-between">
      <label :id="$options.GROUP_BY_LABEL_ID" class="gl-mb-0 gl-font-normal">{{
        $options.i18n.groupBy
      }}</label>
      <gl-collapsible-listbox
        disabled
        size="small"
        :toggle-text="strategy.label"
        :items="groupByOptions"
        :selected="strategy.property"
        :toggle-aria-labelled-by="$options.GROUP_BY_LABEL_ID"
        data-testid="group-by-listbox"
      />
    </div>
    <div class="gl-mb-4 gl-flex gl-items-center gl-justify-between">
      <label :id="$options.SORT_LABEL_ID" class="gl-mb-0 gl-font-normal">{{
        $options.i18n.sort
      }}</label>
      <gl-collapsible-listbox
        size="small"
        :toggle-text="sortToggleText"
        :items="sortByOptions"
        :selected="groupSort"
        :toggle-aria-labelled-by="$options.SORT_LABEL_ID"
        data-testid="sort-listbox"
        @select="handleSortSelect"
      />
    </div>
    <div class="gl-border-t gl-pt-4">
      <span>{{ $options.i18n.groups }}</span>
      <gl-search-box-by-type
        v-model="searchQuery"
        :placeholder="$options.i18n.searchPlaceholder"
        class="gl-mt-3"
        data-testid="group-by-search"
      />
      <gl-loading-icon v-if="isLoading" class="gl-mt-4" />
      <p
        v-else-if="noGroupsAvailable"
        data-testid="no-groups-found"
        class="gl-mb-0 gl-mt-4 gl-text-sm gl-text-subtle"
      >
        {{ $options.i18n.noGroupsFound }}
      </p>
      <template v-else>
        <p
          v-if="showGroupLimitHint"
          class="gl-mb-0 gl-mt-4 gl-text-sm gl-text-subtle"
          data-testid="group-limit-hint"
        >
          {{ groupLimitHint }}
        </p>
        <div v-if="shownGroups.length" class="gl-mt-4" data-testid="shown-groups">
          <div class="gl-flex gl-items-center gl-justify-between">
            <span class="gl-text-sm gl-font-bold">{{ $options.i18n.shown }}</span>
            <button
              type="button"
              class="gl-border-none gl-bg-transparent gl-p-0 gl-text-sm gl-text-subtle"
              data-testid="hide-all"
              @click="hideAll"
            >
              {{ $options.i18n.hideAll }}
            </button>
          </div>
          <draggable-compat
            :value="shownGroups"
            :item-key="groupRowKey"
            tag="ul"
            class="gl-m-0 gl-mt-2 gl-list-none gl-p-0"
            v-bind="$options.groupSortableOptions"
            :disabled="!isManualSort"
            @end="onGroupMove"
          >
            <li
              v-for="row in shownGroups"
              :key="row.value.id"
              :class="{ 'gl-cursor-grab': isManualSort }"
              class="gl-flex gl-items-center gl-gap-3 gl-py-2"
            >
              <gl-icon v-if="isManualSort" name="grip" data-testid="group-grip" />
              <gl-icon v-if="row.showIcon" :name="row.iconName" :style="row.iconStyle" />
              <gl-toggle
                :value="true"
                :label="row.value.name"
                class="gl-w-full gl-justify-between"
                label-position="left"
                @change="toggleGroupVisibility(row.value)"
              />
            </li>
          </draggable-compat>
        </div>
        <div v-if="hiddenGroups.length" class="gl-mt-4" data-testid="hidden-groups">
          <span class="gl-text-sm gl-font-bold">{{ $options.i18n.hidden }}</span>
          <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0">
            <li
              v-for="row in hiddenGroups"
              :key="row.value.id"
              class="gl-flex gl-items-center gl-gap-3 gl-py-2"
            >
              <gl-icon v-if="row.showIcon" :name="row.iconName" :style="row.iconStyle" />
              <gl-toggle
                :value="false"
                :disabled="isAtGroupLimit"
                :label="row.value.name"
                class="gl-w-full gl-justify-between"
                label-position="left"
                @change="toggleGroupVisibility(row.value)"
              />
            </li>
          </ul>
        </div>
      </template>
    </div>
  </div>
</template>
