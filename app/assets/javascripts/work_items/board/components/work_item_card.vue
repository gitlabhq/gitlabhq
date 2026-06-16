<script>
import { GlLabel, GlTruncate } from '@gitlab/ui';
import { WIDGET_TYPE_LABELS } from '~/work_items/constants';
import { findAssigneesWidget, findStatusWidget } from '~/work_items/utils';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

export default {
  name: 'WorkItemCard',
  components: {
    GlLabel,
    GlTruncate,
    IssuableAssignees,
    WorkItemTypeIcon,
    WorkItemStatusBadge: () =>
      import('ee_component/work_items/components/shared/work_item_status_badge.vue'),
  },
  props: {
    item: {
      required: true,
      type: Object,
    },
  },
  computed: {
    labels() {
      const widget = this.item.widgets?.find((w) => w.type === WIDGET_TYPE_LABELS);
      return widget?.labels?.nodes ?? [];
    },
    assignees() {
      return findAssigneesWidget(this.item)?.assignees?.nodes ?? [];
    },
    status() {
      return findStatusWidget(this.item)?.status ?? null;
    },
    hasFooter() {
      return this.assignees.length > 0 || this.status !== null;
    },
  },
};
</script>

<template>
  <li class="gl-border gl-rounded-lg gl-border-section gl-bg-section hover:gl-bg-subtle">
    <a
      :href="item.webPath"
      data-testid="work-item-link"
      class="gl-flex gl-min-w-0 gl-flex-col gl-gap-2 gl-p-3 gl-text-default hover:gl-text-default hover:gl-no-underline"
    >
      <div class="gl-flex gl-min-w-0 gl-items-center gl-gap-2">
        <work-item-type-icon
          v-if="item.workItemType"
          :work-item-type="item.workItemType.name"
          :type-icon-name="item.workItemType.iconName"
          variant="subtle"
        />
        <h4 class="gl-m-0 gl-min-w-0 gl-text-base gl-font-normal">
          <gl-truncate :text="item.title" with-tooltip />
        </h4>
      </div>
      <div class="gl-mb-2 gl-flex gl-min-w-0 gl-items-center gl-gap-2">
        <span data-testid="work-item-reference" class="gl-text-sm gl-text-subtle">{{
          item.reference
        }}</span>
      </div>
      <div v-if="labels.length" class="gl-flex gl-flex-wrap gl-gap-2">
        <gl-label
          v-for="label in labels"
          :key="label.id"
          :background-color="label.color"
          :title="label.title"
          :description="label.description"
        />
      </div>
      <div
        v-if="hasFooter"
        data-testid="work-item-footer"
        class="gl-flex gl-items-center gl-justify-end gl-gap-2"
      >
        <issuable-assignees
          v-if="assignees.length"
          :assignees="assignees"
          :icon-size="16"
          :max-visible="3"
          class="gl-flex gl-items-center"
        />
        <work-item-status-badge v-if="status" :item="status" />
      </div>
    </a>
  </li>
</template>
