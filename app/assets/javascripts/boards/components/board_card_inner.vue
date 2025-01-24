<script>
import { GlLabel, GlTooltipDirective, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { sortBy } from 'lodash';
import boardCardInner from 'ee_else_ce/boards/mixins/board_card_inner';
import { isScopedLabel, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { updateHistory, queryToObject } from '~/lib/utils/url_utility';
import { sprintf, __, n__ } from '~/locale';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssuableBlockedIcon from '~/vue_shared/components/issuable_blocked_icon/issuable_blocked_icon.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import { ListType } from '../constants';
import { setError } from '../graphql/cache_updates';
import IssueDueDate from './issue_due_date.vue';
import IssueTimeEstimate from './issue_time_estimate.vue';

export default {
  components: {
    GlLabel,
    GlLoadingIcon,
    GlIcon,
    UserAvatarLink,
    IssueDueDate,
    IssueTimeEstimate,
    IssueWeight: () => import('ee_component/issues/components/issue_weight.vue'),
    IssueIteration: () => import('ee_component/boards/components/issue_iteration.vue'),
    IssuableBlockedIcon,
    WorkItemTypeIcon,
    IssueMilestone,
    IssueHealthStatus: () =>
      import('ee_component/related_items_tree/components/issue_health_status.vue'),
    EpicCountables: () =>
      import('ee_else_ce/vue_shared/components/epic_countables/epic_countables.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [boardCardInner, glFeatureFlagsMixin()],
  inject: [
    'allowSubEpics',
    'rootPath',
    'scopedLabelsAvailable',
    'isEpicBoard',
    'issuableType',
    'isGroupBoard',
    'disabled',
  ],
  props: {
    item: {
      type: Object,
      required: true,
    },
    list: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    updateFilters: {
      type: Boolean,
      required: false,
      default: false,
    },
    index: {
      type: Number,
      required: true,
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      limitBeforeCounter: 2,
      maxRender: 3,
      maxCounter: 99,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    isShowingLabels: {
      query: isShowingLabelsQuery,
      update: (data) => data.isShowingLabels,
    },
  },
  computed: {
    isLoading() {
      return this.item.isLoading || this.item.iid === '-1';
    },
    cappedAssignees() {
      // e.g. maxRender is 4,
      // Render up to all 4 assignees if there are only 4 assigness
      // Otherwise render up to the limitBeforeCounter
      if (this.item.assignees.length <= this.maxRender) {
        return this.item.assignees.slice(0, this.maxRender);
      }

      return this.item.assignees.slice(0, this.limitBeforeCounter);
    },
    numberOverLimit() {
      return this.item.assignees.length - this.limitBeforeCounter;
    },
    assigneeCounterTooltip() {
      const { numberOverLimit, maxCounter } = this;
      const count = numberOverLimit > maxCounter ? maxCounter : numberOverLimit;
      return sprintf(__('%{count} more assignees'), { count });
    },
    assigneeCounterLabel() {
      if (this.numberOverLimit > this.maxCounter) {
        return `${this.maxCounter}+`;
      }

      return `+${this.numberOverLimit}`;
    },
    shouldRenderCounter() {
      if (this.item.assignees.length <= this.maxRender) {
        return false;
      }

      return this.item.assignees.length > this.numberOverLimit;
    },
    itemPrefix() {
      return this.isEpicBoard ? '&' : '#';
    },
    itemId() {
      if (this.item.iid) {
        return `${this.itemPrefix}${this.item.iid}`;
      }
      return false;
    },
    hasChildren() {
      return this.totalIssuesCount + this.totalEpicsCount > 0;
    },
    shouldRenderEpicCountables() {
      return this.isEpicBoard && this.hasChildren;
    },
    showLabelFooter() {
      return this.isShowingLabels && this.item.labels.filter(this.isNonListLabel).length > 0;
    },
    itemReferencePath() {
      const { referencePath } = this.item;
      return referencePath.split(this.itemPrefix)[0];
    },
    directNamespaceReference() {
      return this.itemReferencePath.split('/').slice(-1)[0];
    },
    orderedLabels() {
      return sortBy(this.item.labels.filter(this.isNonListLabel), 'title');
    },
    blockedLabel() {
      if (this.item.blockedByCount) {
        return n__(`Blocked by %d issue`, `Blocked by %d issues`, this.item.blockedByCount);
      }
      return __('Blocked issue');
    },
    descendantCounts() {
      return this.item.descendantCounts;
    },
    descendantWeightSum() {
      return this.item.descendantWeightSum;
    },
    totalEpicsCount() {
      return this.descendantCounts.openedEpics + this.descendantCounts.closedEpics;
    },
    totalIssuesCount() {
      return this.descendantCounts.openedIssues + this.descendantCounts.closedIssues;
    },
    showReferencePath() {
      return this.isGroupBoard && this.itemReferencePath;
    },
    avatarSize() {
      return { default: 16, lg: 24 };
    },
    showBoardCardNumber() {
      return this.item.referencePath && !this.isLoading;
    },
    hasActions() {
      return !this.disabled && this.list.listType !== ListType.closed;
    },
    workItemDrawerEnabled() {
      if (gon.current_user_use_work_items_view) return true;
      return this.isEpicBoard ? this.glFeatures.epicsListDrawer : this.glFeatures.issuesListDrawer;
    },
  },
  methods: {
    setError,
    isIndexLessThanlimit(index) {
      return index < this.limitBeforeCounter;
    },
    assigneeUrl(assignee) {
      if (!assignee) return '';
      return `${this.rootPath}${assignee.username}`;
    },
    avatarUrlTitle(assignee) {
      return sprintf(__(`Avatar for %{assigneeName}`), { assigneeName: assignee.name });
    },
    avatarUrl(assignee) {
      return assignee.avatarUrl || assignee.avatar || gon.default_avatar_url;
    },
    isNonListLabel(label) {
      return (
        label.id &&
        !(
          (this.list.type || this.list.listType) === ListType.label &&
          this.list.title === label.title
        )
      );
    },
    filterByLabel(label) {
      if (!this.updateFilters) return;

      const filterPath = window.location.search ? `${window.location.search}&` : '?';
      const filter = `label_name[]=${encodeURIComponent(label.title)}`;

      if (!filterPath.includes(filter)) {
        updateHistory({
          url: `${filterPath}${filter}`,
        });

        const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });
        const filters = convertObjectPropsToCamelCase(rawFilterParams, {});
        this.$emit('setFilters', filters);
      }
    },
    showScopedLabel(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-flex" dir="auto">
      <h4
        class="board-card-title gl-mb-0 gl-mt-0 gl-min-w-0 gl-hyphens-auto gl-break-words gl-text-base"
        :class="{ 'gl-mr-6': hasActions }"
      >
        <issuable-blocked-icon
          v-if="item.blocked"
          :item="item"
          :unique-id="`${item.id}${list.id}`"
          :issuable-type="issuableType"
          @blocking-issuables-error="setError"
        />
        <gl-icon
          v-if="item.confidential"
          v-gl-tooltip
          name="eye-slash"
          data-testid="confidential-icon"
          :title="__('Confidential')"
          class="gl-mr-2 gl-cursor-help"
          :aria-label="__('Confidential')"
          variant="warning"
        />
        <gl-icon
          v-if="item.hidden"
          v-gl-tooltip
          name="spam"
          :title="__('This issue is hidden because its author has been banned.')"
          class="hidden-icon gl-mr-2 gl-cursor-help"
          data-testid="hidden-icon"
          variant="warning"
        />
        <a
          :href="item.path || item.webUrl || ''"
          :title="item.title"
          :class="{
            '!gl-text-disabled': isLoading,
            'js-no-trigger': !workItemDrawerEnabled,
            'js-no-trigger-title': workItemDrawerEnabled,
          }"
          class="gl-text-default hover:gl-text-default"
          data-testid="board-card-title-link"
          @mousemove.stop
          >{{ item.title }}</a
        >
      </h4>
      <slot></slot>
    </div>
    <div v-if="showLabelFooter" class="board-card-labels gl-mt-2 gl-flex gl-flex-wrap">
      <template v-for="label in orderedLabels">
        <gl-label
          :key="label.id"
          class="js-no-trigger gl-mr-2 gl-mt-2"
          :background-color="label.color"
          :title="label.title"
          :description="label.description"
          :scoped="showScopedLabel(label)"
          target="#"
          @click="filterByLabel(label)"
        />
      </template>
    </div>
    <div class="board-card-footer gl-mt-3 gl-flex gl-items-end gl-justify-between">
      <div
        class="align-items-start board-card-number-container gl-flex gl-flex-wrap-reverse gl-overflow-hidden"
      >
        <span class="board-info-items gl-inline-block gl-leading-20">
          <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
          <span
            v-if="showBoardCardNumber"
            class="board-card-number gl-mr-3 gl-mt-3 gl-gap-2 gl-overflow-hidden gl-text-sm gl-text-subtle"
            :class="{ 'gl-text-base': isEpicBoard }"
          >
            <work-item-type-icon
              v-if="showWorkItemTypeIcon"
              :work-item-type="item.type"
              show-tooltip-on-hover
            />
            <span
              v-if="showReferencePath"
              v-gl-tooltip
              :title="itemReferencePath"
              data-placement="bottom"
              class="board-item-path gl-cursor-help gl-truncate gl-font-bold"
            >
              {{ directNamespaceReference }}
            </span>
            {{ itemId }}
          </span>
          <epic-countables
            v-if="shouldRenderEpicCountables"
            :allow-sub-epics="allowSubEpics"
            :opened-epics-count="descendantCounts.openedEpics"
            :closed-epics-count="descendantCounts.closedEpics"
            :opened-issues-count="descendantCounts.openedIssues"
            :closed-issues-count="descendantCounts.closedIssues"
            :opened-issues-weight="descendantWeightSum.openedIssues"
            :closed-issues-weight="descendantWeightSum.closedIssues"
          />
          <span v-if="!isEpicBoard">
            <issue-weight v-if="validIssueWeight(item)" :weight="item.weight" />
            <issue-milestone
              v-if="item.milestone"
              data-testid="issue-milestone"
              :milestone="item.milestone"
              class="gl-mr-3 gl-inline-flex gl-max-w-15 gl-cursor-help gl-items-center gl-align-bottom gl-text-sm gl-text-subtle"
            />
            <issue-iteration
              v-if="item.iteration"
              data-testid="issue-iteration"
              :iteration="item.iteration"
              class="gl-align-bottom"
            />
            <issue-due-date
              v-if="item.dueDate"
              :date="item.dueDate"
              :closed="Boolean(item.closedAt)"
            />
            <issue-time-estimate v-if="item.timeEstimate" :estimate="item.timeEstimate" />
            <issue-health-status v-if="item.healthStatus" :health-status="item.healthStatus" />
          </span>
        </span>
      </div>
      <div class="board-card-assignee gl-flex">
        <user-avatar-link
          v-for="assignee in cappedAssignees"
          :key="assignee.id"
          :link-href="assigneeUrl(assignee)"
          :img-alt="avatarUrlTitle(assignee)"
          :img-src="avatarUrl(assignee)"
          :img-size="avatarSize"
          class="js-no-trigger user-avatar-link"
          tooltip-placement="bottom"
        >
          <span class="js-assignee-tooltip">
            <span class="gl-block gl-font-bold">{{ __('Assignee') }}</span>
            {{ assignee.name }}
            <span>@{{ assignee.username }}</span>
          </span>
        </user-avatar-link>
        <span
          v-if="shouldRenderCounter"
          v-gl-tooltip
          :title="assigneeCounterTooltip"
          class="avatar-counter -gl-ml-3 gl-cursor-help gl-border-0 gl-bg-gray-100 gl-font-bold gl-leading-24 gl-text-default"
          data-placement="bottom"
          >{{ assigneeCounterLabel }}</span
        >
      </div>
    </div>
  </div>
</template>
