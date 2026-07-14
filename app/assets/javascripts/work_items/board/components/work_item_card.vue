<script>
import { uniqueId } from 'lodash-es';
import { GlLabel, GlTruncate } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { WIDGET_TYPE_LABELS, METADATA_KEYS } from '~/work_items/constants';
import {
  findAssigneesWidget,
  findStatusWidget,
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findWeightWidget,
  findIterationWidget,
  findHealthStatusWidget,
  findLinkedItemsWidget,
  findHierarchyWidget,
  getDisplayReference,
} from '~/work_items/utils';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import WorkItemRelationshipIcons from '~/work_items/components/shared/work_item_relationship_icons.vue';
import WorkItemParentMetadata from '~/work_items/components/shared/work_item_parent_metadata.vue';

export default {
  name: 'WorkItemCard',
  components: {
    GlLabel,
    GlTruncate,
    IssuableAssignees,
    WorkItemTypeIcon,
    IssueMilestone,
    IssueDueDate,
    WorkItemRelationshipIcons,
    WorkItemParentMetadata,
    IssueWeight: () => import('ee_component/issues/components/issue_weight.vue'),
    IssueIteration: () => import('ee_component/boards/components/issue_iteration.vue'),
    IssueHealthStatus: () => import('ee_component/issues/components/issue_health_status.vue'),
    WorkItemStatusBadge: () =>
      import('ee_component/work_items/components/shared/work_item_status_badge.vue'),
  },
  props: {
    item: {
      required: true,
      type: Object,
    },
    hiddenMetadataKeys: {
      type: Array,
      required: false,
      default: () => [],
    },
    rootPageFullPath: {
      type: String,
      required: false,
      default: '',
    },
    activeItem: {
      required: false,
      type: Object,
      default: null,
    },
    detailPanelEnabled: {
      required: false,
      type: Boolean,
      default: true,
    },
  },
  emits: ['set-active-item'],
  computed: {
    reference() {
      // Items that live in the board's own namespace are shortened to `#iid`;
      // items from a different namespace (e.g. on a group board) keep the full
      // reference so their project is identifiable.
      return getDisplayReference(this.rootPageFullPath, this.item.reference);
    },
    isActive() {
      return (
        Boolean(this.activeItem) &&
        getIdFromGraphQLId(this.item.id) === getIdFromGraphQLId(this.activeItem.id)
      );
    },
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
    milestone() {
      return findMilestoneWidget(this.item)?.milestone ?? null;
    },
    dueDate() {
      return findStartAndDueDateWidget(this.item)?.dueDate ?? null;
    },
    weight() {
      return findWeightWidget(this.item)?.weight ?? null;
    },
    iteration() {
      return findIterationWidget(this.item)?.iteration ?? null;
    },
    healthStatus() {
      return findHealthStatusWidget(this.item)?.healthStatus ?? null;
    },
    linkedItems() {
      return findLinkedItemsWidget(this.item);
    },
    blockingCount() {
      return this.linkedItems?.blockingCount ?? 0;
    },
    blockedByCount() {
      return this.linkedItems?.blockedByCount ?? 0;
    },
    parent() {
      return findHierarchyWidget(this.item)?.parent ?? null;
    },
    targetId() {
      return uniqueId(`work-item-card-${this.item.iid}-`);
    },
    showLabels() {
      return this.labels.length > 0 && !this.isMetadataHidden(METADATA_KEYS.LABELS);
    },
    showAssignees() {
      return this.assignees.length > 0 && !this.isMetadataHidden(METADATA_KEYS.ASSIGNEE);
    },
    showStatus() {
      return this.status !== null && !this.isMetadataHidden(METADATA_KEYS.STATUS);
    },
    showWeight() {
      return this.weight != null && !this.isMetadataHidden(METADATA_KEYS.WEIGHT);
    },
    showMilestone() {
      return Boolean(this.milestone) && !this.isMetadataHidden(METADATA_KEYS.MILESTONE);
    },
    showIteration() {
      return Boolean(this.iteration) && !this.isMetadataHidden(METADATA_KEYS.ITERATION);
    },
    showDates() {
      return Boolean(this.dueDate) && !this.isMetadataHidden(METADATA_KEYS.DATES);
    },
    showHealthStatus() {
      return Boolean(this.healthStatus) && !this.isMetadataHidden(METADATA_KEYS.HEALTH);
    },
    showParent() {
      return Boolean(this.parent) && !this.isMetadataHidden(METADATA_KEYS.PARENT);
    },
    showRelationshipIcons() {
      return (
        (this.blockingCount > 0 || this.blockedByCount > 0) &&
        !this.isMetadataHidden(METADATA_KEYS.BLOCKED)
      );
    },
    hasFooter() {
      return (
        this.showAssignees || this.showHealthStatus || this.showRelationshipIcons || this.showStatus
      );
    },
  },
  methods: {
    isMetadataHidden(key) {
      return this.hiddenMetadataKeys.includes(key);
    },
    handleCardClick(event) {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.button === 1) {
        return;
      }
      event.preventDefault();
      if (!this.detailPanelEnabled) {
        visitUrl(this.item.webPath);
        return;
      }
      this.$emit('set-active-item', this.isActive ? null : this.item);
    },
  },
};
</script>

<template>
  <li
    :data-work-item-id="item.id"
    data-testid="work-item-board-card"
    :class="{ 'is-active !gl-bg-blue-50 hover:!gl-bg-blue-50': isActive }"
    class="js-board-card gl-border gl-rounded-lg gl-border-section gl-bg-section hover:gl-bg-subtle"
  >
    <a
      :href="item.webPath"
      data-testid="work-item-link"
      class="gl-flex gl-min-w-0 gl-flex-col gl-gap-2 gl-p-3 gl-text-default hover:gl-text-default hover:gl-no-underline"
      @click="handleCardClick"
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
      <div
        data-testid="work-item-metadata"
        class="gl-flex gl-flex-wrap gl-items-center gl-gap-x-3 gl-gap-y-2 gl-text-sm gl-text-subtle"
      >
        <span data-testid="work-item-reference">{{ reference }}</span>
        <work-item-parent-metadata
          v-if="showParent"
          data-testid="work-item-parent"
          :parent="parent"
          :icon-size="12"
        />
        <issue-weight v-if="showWeight" data-testid="work-item-weight" :weight="weight" />
        <issue-milestone
          v-if="showMilestone"
          data-testid="work-item-milestone"
          :milestone="milestone"
          class="gl-flex gl-max-w-15 gl-cursor-help gl-items-center gl-align-bottom"
        />
        <issue-iteration
          v-if="showIteration"
          data-testid="work-item-iteration"
          :iteration="iteration"
        />
        <issue-due-date
          v-if="showDates"
          data-testid="work-item-due-date"
          :date="dueDate"
          :closed="Boolean(item.closedAt)"
        />
      </div>
      <div v-if="showLabels" class="gl-flex gl-flex-wrap gl-gap-2">
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
        class="gl-flex gl-items-center gl-justify-end gl-gap-3"
      >
        <issuable-assignees
          v-if="showAssignees"
          :assignees="assignees"
          :icon-size="16"
          :max-visible="3"
          class="gl-flex gl-items-center"
        />
        <issue-health-status
          v-if="showHealthStatus"
          data-testid="work-item-health-status"
          display-as-text
          text-size="sm"
          :health-status="healthStatus"
        />
        <!-- eslint-disable local-rules/vue-no-web-url -- WorkItemRelationshipIcons builds an absolute "view all linked items" link from this URL, so it needs webUrl rather than the relative webPath. -->
        <work-item-relationship-icons
          v-if="showRelationshipIcons"
          :work-item-type="item.workItemType.name"
          :work-item-full-path="item.namespace.fullPath"
          :work-item-iid="item.iid"
          :work-item-web-url="item.webUrl"
          :blocking-count="blockingCount"
          :blocked-by-count="blockedByCount"
          :target-id="targetId"
        />
        <!-- eslint-enable local-rules/vue-no-web-url -->
        <work-item-status-badge v-if="showStatus" :item="status" />
      </div>
    </a>
  </li>
</template>
