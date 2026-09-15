<script>
import {
  GlButton,
  GlButtonGroup,
  GlDrawer,
  GlIcon,
  GlSegmentedControl,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { groupingStrategyFor } from '~/work_items/board/grouping';
import {
  DISPLAY_SETTINGS_PAGE_GROUP_BY,
  DISPLAY_SETTINGS_PAGE_ROOT,
  VIEW_MODE_LIST,
  VIEW_MODE_BOARD,
  VIEW_MODE_TABLE,
} from '../../constants';
import WorkItemDisplaySettingsSort from './work_item_display_settings_sort.vue';
import WorkItemDisplaySettingsMetadata from './work_item_display_settings_metadata.vue';
import WorkItemDisplaySettingsUserPreferences from './work_item_display_settings_user_preferences.vue';
import WorkItemDisplaySettingsGroupBy from './work_item_display_settings_group_by.vue';

export default {
  name: 'WorkItemDisplaySettingsDrawer',
  components: {
    GlButton,
    GlButtonGroup,
    GlDrawer,
    GlIcon,
    GlSegmentedControl,
    WorkItemDisplaySettingsSort,
    WorkItemDisplaySettingsMetadata,
    WorkItemDisplaySettingsUserPreferences,
    WorkItemDisplaySettingsGroupBy,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  i18n: {
    title: s__('WorkItems|Display'),
    groupBy: s__('WorkItems|Group by'),
    goBack: __('Go back'),
  },
  viewModeOptions: [
    {
      value: VIEW_MODE_LIST,
      text: s__('WorkItemPlanningView|List'),
      props: { icon: 'list-bulleted' },
    },
    {
      value: VIEW_MODE_TABLE,
      text: s__('WorkItemPlanningView|Table'),
      props: { icon: 'table' },
    },
    {
      value: VIEW_MODE_BOARD,
      text: s__('WorkItemPlanningView|Board (Beta)'),
      props: { icon: 'work-item-issue-board' },
    },
  ],
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    headerHeight: {
      type: String,
      required: false,
      default: '',
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemTypeId: {
      type: String,
      required: true,
    },
    viewMode: {
      type: String,
      required: false,
      default: VIEW_MODE_LIST,
    },
    sortOptions: {
      type: Array,
      required: false,
      default: () => [],
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
    commonPreferences: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isServiceDeskList: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSavedView: {
      type: Boolean,
      required: false,
      default: false,
    },
    page: {
      type: String,
      required: false,
      default: DISPLAY_SETTINGS_PAGE_ROOT,
    },
  },
  emits: ['close', 'sort', 'update-settings', 'toggle-view-mode', 'page-change'],
  computed: {
    hasSortOptions() {
      return this.viewMode !== VIEW_MODE_BOARD && this.sortOptions.length > 0;
    },
    isPlanningViewBoardEnabled() {
      return Boolean(this.glFeatures.planningViewBoards);
    },
    isPlanningViewTableEnabled() {
      return Boolean(this.glFeatures.planningViewTable);
    },
    labelledViewModeOptions() {
      return this.$options.viewModeOptions.filter((option) => option.value !== VIEW_MODE_TABLE);
    },
    iconViewModeOptions() {
      return this.$options.viewModeOptions.filter(
        (option) => option.value !== VIEW_MODE_BOARD || this.isPlanningViewBoardEnabled,
      );
    },
    isGroupByPage() {
      return this.page === DISPLAY_SETTINGS_PAGE_GROUP_BY;
    },
    showGroupByRow() {
      return this.isPlanningViewBoardEnabled && this.viewMode === VIEW_MODE_BOARD;
    },
    groupByLabel() {
      return groupingStrategyFor('status')?.label ?? '';
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSort(newSortKey) {
      this.$emit('sort', newSortKey);
    },
    onSettingsUpdate(input) {
      this.$emit('update-settings', input);
    },
    onToggleViewMode(newViewMode) {
      this.$emit('toggle-view-mode', newViewMode);
    },
    openGroupByPage() {
      this.$emit('page-change', DISPLAY_SETTINGS_PAGE_GROUP_BY);
    },
    backToRoot() {
      this.$emit('page-change', DISPLAY_SETTINGS_PAGE_ROOT);
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :header-height="headerHeight"
    :style="{ '--drawer-top-offset': headerHeight || '0px' }"
    header-sticky
    :z-index="$options.DRAWER_Z_INDEX"
    class="work-item-display-settings-drawer gl-duration-fast"
    data-testid="display-settings-drawer"
    @close="onClose"
  >
    <template #title>
      <div v-if="isGroupByPage" class="gl-flex gl-items-center gl-gap-3">
        <gl-button
          category="tertiary"
          icon="chevron-lg-left"
          size="small"
          :aria-label="$options.i18n.goBack"
          data-testid="group-by-back-button"
          @click="backToRoot"
        />
        <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">{{ $options.i18n.groupBy }}</h2>
      </div>
      <h2 v-else class="gl-my-0 gl-text-size-h2 gl-leading-24">{{ $options.i18n.title }}</h2>
    </template>
    <template #default>
      <work-item-display-settings-group-by
        v-if="isGroupByPage"
        :full-path="fullPath"
        :work-item-type-id="workItemTypeId"
        :sort-key="sortKey"
        :namespace-preferences="namespacePreferences"
        :is-saved-view="isSavedView"
        @update-settings="onSettingsUpdate"
      />
      <div v-else class="gl-flex gl-h-full gl-flex-col !gl-p-0">
        <gl-button-group
          v-if="isPlanningViewTableEnabled"
          class="gl-mx-5 gl-mt-5"
          data-testid="icon-view-mode-toggle"
        >
          <gl-button
            v-for="option in iconViewModeOptions"
            :key="option.value"
            v-gl-tooltip
            :icon="option.props.icon"
            :title="option.text"
            :aria-label="option.text"
            :aria-pressed="option.value === viewMode ? 'true' : 'false'"
            :selected="option.value === viewMode"
            :data-testid="`view-mode-${option.value}`"
            @click="onToggleViewMode(option.value)"
          />
        </gl-button-group>
        <gl-segmented-control
          v-else-if="isPlanningViewBoardEnabled"
          :options="labelledViewModeOptions"
          :value="viewMode"
          class="gl-mx-5 gl-mt-5"
          data-testid="view-mode-toggle"
          @input="onToggleViewMode"
        />
        <work-item-display-settings-sort
          v-if="hasSortOptions"
          :sort-options="sortOptions"
          :sort-key="sortKey"
          class="gl-px-5 gl-pb-4 gl-pt-5"
          @sort="onSort"
        />
        <button
          v-if="showGroupByRow"
          type="button"
          data-testid="group-by-row"
          class="gl-flex gl-w-full gl-items-center gl-justify-between gl-border-none gl-bg-transparent gl-px-5 gl-py-4"
          @click="openGroupByPage"
        >
          <span>{{ $options.i18n.groupBy }}</span>
          <span class="gl-flex gl-items-center gl-gap-2 gl-text-subtle">
            {{ groupByLabel }}
            <gl-icon name="chevron-right" />
          </span>
        </button>
        <div class="gl-border-t gl-p-2 gl-pt-5">
          <work-item-display-settings-metadata
            :namespace-preferences="namespacePreferences"
            :full-path="fullPath"
            :is-service-desk-list="isServiceDeskList"
            :is-saved-view="isSavedView"
            :work-item-type-id="workItemTypeId"
            :sort-key="sortKey"
            :view-mode="viewMode"
            @update-settings="onSettingsUpdate"
          />
          <work-item-display-settings-user-preferences
            class="!gl-border-t gl-mt-auto gl-pb-5 gl-pt-5"
            :common-preferences="commonPreferences"
            :full-path="fullPath"
            :is-saved-view="isSavedView"
            :work-item-type-id="workItemTypeId"
          />
        </div>
      </div>
    </template>
  </gl-drawer>
</template>
