<script>
import {
  GlCollapsibleListbox,
  GlIcon,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlToggle,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import {
  groupingStrategyFor,
  hasDecorationIcon,
  decorationIconStyle,
} from '~/work_items/board/grouping';
import { getGroupId } from '~/work_items/board/utils';
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
  // Status is the only supported grouping today, so the identifier scheme is
  // scoped to it. Kept generic so future groupings can reuse the same shape.
  groupBy: { property: 'status' },
  GROUP_BY_LABEL_ID: 'work-item-display-settings-group-by-label',
  SORT_LABEL_ID: 'work-item-display-settings-sort-label',
  data() {
    return {
      groupByValues: [],
    };
  },
  apollo: {
    groupByValues() {
      return {
        query: this.strategy.valuesQuery,
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
  computed: {
    strategy() {
      return groupingStrategyFor('status');
    },
    isLoading() {
      return this.$apollo.queries.groupByValues.loading;
    },
    groupByOptions() {
      return [{ text: this.strategy.label, value: this.strategy.property }];
    },
    sortByOptions() {
      return [{ text: this.$options.i18n.ascending, value: 'asc' }];
    },
    decoratedGroupByValues() {
      return this.groupByValues.map((value) => {
        const decoration = this.strategy.headerDecoration(value);
        return {
          value,
          showIcon: hasDecorationIcon(decoration),
          iconName: decoration.name,
          iconStyle: decorationIconStyle(decoration),
        };
      });
    },
    // null means every group is visible; otherwise it holds the ids of the
    // groups to render.
    visibleGroups() {
      return this.namespacePreferences?.visibleGroups ?? null;
    },
    allGroupIds() {
      return this.groupByValues.map((value) => this.groupId(value));
    },
  },
  methods: {
    groupId(value) {
      return getGroupId({ groupBy: this.$options.groupBy, value });
    },
    isGroupVisible(value) {
      return this.visibleGroups === null || this.visibleGroups.includes(this.groupId(value));
    },
    toggleGroupVisibility(value) {
      const id = this.groupId(value);
      const current = this.visibleGroups ?? this.allGroupIds;
      const nextVisible = current.includes(id)
        ? current.filter((groupId) => groupId !== id)
        : [...current, id];

      // Collapse back to null once every group is shown again so the "all
      // visible" default stays represented consistently.
      const normalized = this.allGroupIds.every((groupId) => nextVisible.includes(groupId))
        ? null
        : nextVisible;

      this.persist(normalized);
    },
    hideAll() {
      if (this.visibleGroups?.length === 0) return;
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
        disabled
        :placeholder="$options.i18n.searchPlaceholder"
        class="gl-mt-3"
        data-testid="group-by-search"
      />
      <gl-loading-icon v-if="isLoading" class="gl-mt-4" />
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
        <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0" data-testid="group-by-values">
          <li
            v-for="row in decoratedGroupByValues"
            :key="row.value.id"
            class="gl-flex gl-items-center gl-gap-3 gl-py-2"
          >
            <gl-icon v-if="row.showIcon" :name="row.iconName" :style="row.iconStyle" />
            <gl-toggle
              :value="isGroupVisible(row.value)"
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
