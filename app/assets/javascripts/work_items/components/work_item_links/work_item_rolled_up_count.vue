<script>
import { GlPopover, GlBadge, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import WorkItemRolledUpCountInfo from './work_item_rolled_up_count_info.vue';

export default {
  i18n: {
    countPermissionText: __('Roll up totals may reflect child items you don’t have access to.'),
    noChildItemsText: __('No child items are currently assigned.'),
  },
  components: {
    GlPopover,
    GlBadge,
    GlIcon,
    WorkItemTypeIcon,
    WorkItemRolledUpCountInfo,
  },
  props: {
    infoType: {
      type: String,
      required: false,
      default: 'badge',
    },
    rolledUpCountsByType: {
      type: Array,
      required: true,
      default: () => [],
    },
    hideCountWhenZero: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    totalCountAllByType() {
      return [...this.rolledUpCountsByType].reduce(
        (total, rollUpCounts) => total + rollUpCounts.countsByState.all,
        0,
      );
    },
    showDetailedCount() {
      return this.infoType === 'detailed';
    },
    filteredRollUpCountsByType() {
      return this.rolledUpCountsByType.filter((rollUpCount) =>
        this.rolledUpCountExists(rollUpCount),
      );
    },
    showRolledUpCount() {
      return this.hideCountWhenZero ? this.totalCountAllByType > 0 : true;
    },
  },
  methods: {
    workItemTypeCount(workItemTypeName) {
      return this.rolledUpCountsByType.find(
        (rollUpCount) => rollUpCount?.workItemType?.name === workItemTypeName,
      );
    },
    rolledUpCountExists(rolledUpCount) {
      return rolledUpCount?.countsByState?.all > 0;
    },
  },
};
</script>
<template>
  <div v-if="showRolledUpCount" data-testid="work-item-rolled-up-count-wrapper">
    <span
      v-if="showDetailedCount"
      ref="info"
      tabindex="0"
      class="gl-flex gl-gap-3 gl-text-nowrap gl-text-sm"
      data-testid="work-item-rolled-up-detailed-count"
    >
      <span
        v-for="rolledUpCount in filteredRollUpCountsByType"
        :key="rolledUpCount.workItemType.name"
      >
        <work-item-type-icon :work-item-icon-name="rolledUpCount.workItemType.iconName" />
        {{ rolledUpCount.countsByState.all }}
      </span>
    </span>

    <span
      v-else
      ref="countBadge"
      tabindex="0"
      class="gl-inline-block"
      data-testid="work-item-rolled-up-badge-count"
    >
      <gl-badge variant="muted">{{ totalCountAllByType }}</gl-badge>
    </span>

    <gl-popover
      v-if="showDetailedCount"
      triggers="hover focus"
      :target="() => $refs.info"
      data-testid="detailed-popover"
    >
      <work-item-rolled-up-count-info
        :filtered-roll-up-counts-by-type="filteredRollUpCountsByType"
      />
    </gl-popover>

    <gl-popover
      v-else
      triggers="hover focus"
      :target="() => $refs.countBadge"
      data-testid="badge-popover"
    >
      <work-item-rolled-up-count-info
        :filtered-roll-up-counts-by-type="filteredRollUpCountsByType"
      />
      <div
        class="gl-text-subtle"
        :class="{ 'gl-mt-3': totalCountAllByType > 0 }"
        data-testid="badge-warning"
      >
        <gl-icon
          v-if="totalCountAllByType > 0"
          name="information-o"
          class="gl-mr-2"
          :size="16"
          variant="subtle"
        />{{
          totalCountAllByType > 0
            ? $options.i18n.countPermissionText
            : $options.i18n.noChildItemsText
        }}
      </div>
    </gl-popover>
  </div>
</template>
