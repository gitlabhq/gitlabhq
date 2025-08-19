<script>
import { GlIcon, GlTooltip, GlPopover } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { i18n, WORK_ITEM_TYPE_NAME_EPIC } from '../../constants';
import { findHealthStatusWidget, findWeightWidget } from '../../utils';

export default {
  components: {
    GlIcon,
    GlTooltip,
    GlPopover,
    WorkItemRolledUpHealthStatus: () =>
      import(
        'ee_component/work_items/components/work_item_links/work_item_rolled_up_health_status.vue'
      ),
  },
  mixins: [glFeatureFlagsMixin()],
  i18n: {
    progressLabel: s__('WorkItem|Progress'),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      workItem: {},
      error: null,
    };
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItem || {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(e) {
        this.$emit('error', i18n.fetchError);
        this.error = e.message || i18n.fetchError;
      },
    },
  },
  computed: {
    workItemWeight() {
      return findWeightWidget(this.workItem);
    },
    workItemHealthStatus() {
      return findHealthStatusWidget(this.workItem);
    },
    shouldRolledUpWeightBeVisible() {
      return this.rolledUpWeight !== null;
    },
    showRolledUpProgress() {
      return this.rolledUpWeight && this.rolledUpCompletedWeight !== null;
    },
    rolledUpWeight() {
      return this.workItemWeight?.rolledUpWeight;
    },
    rolledUpCompletedWeight() {
      return this.workItemWeight?.rolledUpCompletedWeight;
    },
    completedWeightPercentage() {
      return Math.round((this.rolledUpCompletedWeight / this.rolledUpWeight) * 100);
    },
    includeTaskWeights() {
      return (
        this.glFeatures.useCachedRolledUpWeights || this.workItemType !== WORK_ITEM_TYPE_NAME_EPIC
      );
    },
    weightTooltip() {
      return this.includeTaskWeights ? __('Weight') : __('Issue weight');
    },
    weightCompletedLabel() {
      return this.includeTaskWeights
        ? s__('WorkItem|weight completed')
        : s__('WorkItem|issue weight completed');
    },
    rolledUpHealthStatus() {
      return this.workItemHealthStatus?.rolledUpHealthStatus;
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <!-- Rolled up weight -->
    <span
      v-if="shouldRolledUpWeightBeVisible"
      ref="weightData"
      tabindex="0"
      data-testid="work-item-rollup-weight"
      class="gl-flex gl-cursor-help gl-items-center gl-gap-2 gl-font-normal gl-text-subtle sm:gl-ml-3"
    >
      <gl-icon name="weight" variant="subtle" />
      <span data-testid="work-item-weight-value" class="gl-text-sm">{{ rolledUpWeight }}</span>
      <gl-tooltip :target="() => $refs.weightData">
        <span class="gl-font-bold">
          {{ weightTooltip }}
        </span>
      </gl-tooltip>
    </span>
    <!--- END Rolled up weight -->

    <!-- Rolled up Progress -->
    <span
      v-if="showRolledUpProgress"
      ref="progressBadge"
      tabindex="0"
      data-testid="work-item-rollup-progress"
      class="gl-ml-3 gl-flex gl-items-center gl-gap-2 gl-font-normal gl-text-subtle"
    >
      <gl-icon name="progress" variant="subtle" />
      <span data-testid="work-item-progress-value" class="gl-text-sm"
        >{{ completedWeightPercentage }}%</span
      >

      <gl-popover triggers="hover focus" :target="() => $refs.progressBadge">
        <template #title>{{ $options.i18n.progressLabel }}</template>
        <span class="gl-font-bold">{{ rolledUpCompletedWeight }}/{{ rolledUpWeight }}</span>
        <span data-testid="weight-completed-label">{{ weightCompletedLabel }}</span>
      </gl-popover>
    </span>
    <!-- END Rolled up Progress -->

    <!-- Rolled up health status -->
    <work-item-rolled-up-health-status
      v-if="rolledUpHealthStatus"
      :rolled-up-health-status="rolledUpHealthStatus"
    />
    <!-- END Rolled up health status -->
  </div>
</template>
