<script>
import {
  GlCollapsibleListbox,
  GlIcon,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlToggle,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
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
import workItemsGroupByVisibleGroupsQuery from '~/work_items/board/grouping/graphql/client/visible_groups.query.graphql';
import updateVisibleGroupsMutation from '~/work_items/board/grouping/graphql/client/update_visible_groups.mutation.graphql';
import { persistMetadataPreference, alertPreferenceError } from '../display_settings_preferences';

export default {
  name: 'WorkItemDisplaySettingsGroupBy',
  components: {
    GlCollapsibleListbox,
    GlIcon,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlToggle,
  },
  i18n: {
    groupBy: s__('WorkItems|Group by'),
    sort: s__('WorkItems|Sort'),
    ascending: __('Ascending'),
    groups: s__('WorkItems|Groups'),
    searchPlaceholder: s__('WorkItems|Search groups'),
    shown: s__('WorkItems|Shown'),
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
  data() {
    return {
      searchQuery: '',
      groupByValues: [],
      workItemsGroupByVisibleGroups: SHOW_ALL_GROUPS,
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
      return effectiveVisibleGroups(this.workItemsGroupByVisibleGroups, this.groupByValues.length);
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
    sortByOptions() {
      return [{ text: this.$options.i18n.ascending, value: 'asc' }];
    },
    isSearching() {
      return Boolean(this.searchQuery.trim());
    },
    filteredGroupByValues() {
      const query = this.searchQuery.trim().toLowerCase();
      if (!query) return this.groupByValues;
      return this.groupByValues.filter((value) => value.name.toLowerCase().includes(query));
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
    workItemsGroupByVisibleGroups: {
      query: workItemsGroupByVisibleGroupsQuery,
    },
  },
  methods: {
    isGroupVisible(value) {
      return computeGroupVisible(this.visibleGroups, this.groupBy, value);
    },
    async toggleGroupVisibility(value) {
      const next = computeToggleGroupVisibility({
        visibleGroups: this.visibleGroups,
        groupBy: this.groupBy,
        value,
        allGroups: this.groupByValues,
      });
      await this.$apollo.mutate({
        mutation: updateVisibleGroupsMutation,
        variables: { visibleGroups: next },
      });
      this.persist(next);
    },
    async hideAll() {
      // Everything is already hidden, so skip the redundant preference write.
      if (this.visibleGroups?.length === 0) return;
      await this.$apollo.mutate({
        mutation: updateVisibleGroupsMutation,
        variables: { visibleGroups: [] },
      });
      this.persist([]);
    },
    async persist(visibleGroups) {
      const input = { ...this.namespacePreferences, visibleGroups };

      if (this.isSavedView) {
        this.$emit('update-settings', input);
        return;
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
      } catch (error) {
        alertPreferenceError(error);
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
        disabled
        size="small"
        :toggle-text="$options.i18n.ascending"
        :items="sortByOptions"
        selected="asc"
        :toggle-aria-labelled-by="$options.SORT_LABEL_ID"
        data-testid="sort-listbox"
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
        <div class="gl-mt-4 gl-flex gl-items-center gl-justify-between">
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
        <p
          v-if="showGroupLimitHint"
          class="gl-mb-0 gl-mt-2 gl-text-sm gl-text-subtle"
          data-testid="group-limit-hint"
        >
          {{ groupLimitHint }}
        </p>
        <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0" data-testid="group-by-values">
          <li
            v-for="row in decoratedGroupByValues"
            :key="row.value.id"
            class="gl-flex gl-items-center gl-gap-3 gl-py-2"
          >
            <gl-icon v-if="row.showIcon" :name="row.iconName" :style="row.iconStyle" />
            <gl-toggle
              :value="isGroupVisible(row.value)"
              :disabled="isAtGroupLimit && !isGroupVisible(row.value)"
              :label="row.value.name"
              class="gl-w-full gl-justify-between"
              label-position="left"
              @change="toggleGroupVisibility(row.value)"
            />
          </li>
        </ul>
      </template>
    </div>
  </div>
</template>
