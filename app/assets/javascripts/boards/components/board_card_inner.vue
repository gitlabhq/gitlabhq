<script>
import {
  GlLabel,
  GlTooltip,
  GlTooltipDirective,
  GlIcon,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';
import { sortBy } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import boardCardInner from 'ee_else_ce/boards/mixins/board_card_inner';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { updateHistory } from '~/lib/utils/url_utility';
import { sprintf, __, n__ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import { ListType } from '../constants';
import eventHub from '../eventhub';
import BoardBlockedIcon from './board_blocked_icon.vue';
import IssueDueDate from './issue_due_date.vue';
import IssueTimeEstimate from './issue_time_estimate.vue';

export default {
  components: {
    GlTooltip,
    GlLabel,
    GlLoadingIcon,
    GlIcon,
    UserAvatarLink,
    TooltipOnTruncate,
    IssueDueDate,
    IssueTimeEstimate,
    IssueCardWeight: () => import('ee_component/boards/components/issue_card_weight.vue'),
    BoardBlockedIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [boardCardInner],
  inject: ['rootPath', 'scopedLabelsAvailable'],
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
  },
  data() {
    return {
      limitBeforeCounter: 2,
      maxRender: 3,
      maxCounter: 99,
    };
  },
  computed: {
    ...mapState(['isShowingLabels', 'issuableType', 'allowSubEpics']),
    ...mapGetters(['isEpicBoard']),
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
    shouldRenderEpicCountables() {
      return this.isEpicBoard && this.item.hasIssues;
    },
    shouldRenderEpicProgress() {
      return this.totalWeight > 0;
    },
    showLabelFooter() {
      return this.isShowingLabels && this.item.labels.find(this.showLabel);
    },
    itemReferencePath() {
      const { referencePath } = this.item;
      return referencePath.split(this.itemPrefix)[0];
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
    totalEpicsCount() {
      return this.item.descendantCounts.openedEpics + this.item.descendantCounts.closedEpics;
    },
    totalIssuesCount() {
      return this.item.descendantCounts.openedIssues + this.item.descendantCounts.closedIssues;
    },
    totalWeight() {
      return (
        this.item.descendantWeightSum.openedIssues + this.item.descendantWeightSum.closedIssues
      );
    },
    totalProgress() {
      return Math.round((this.item.descendantWeightSum.closedIssues / this.totalWeight) * 100);
    },
  },
  methods: {
    ...mapActions(['performSearch', 'setError']),
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
    showLabel(label) {
      if (!label.id) return false;
      return true;
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
        this.performSearch();
        eventHub.$emit('updateTokens');
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
    <div class="gl-display-flex" dir="auto">
      <h4 class="board-card-title gl-mb-0 gl-mt-0">
        <board-blocked-icon
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
          :title="__('Confidential')"
          class="confidential-icon gl-mr-2"
          :aria-label="__('Confidential')"
        />
        <a
          :href="item.path || item.webUrl || ''"
          :title="item.title"
          :class="{ 'gl-text-gray-400!': item.isLoading }"
          @mousemove.stop
          >{{ item.title }}</a
        >
      </h4>
    </div>
    <div v-if="showLabelFooter" class="board-card-labels gl-mt-2 gl-display-flex gl-flex-wrap">
      <template v-for="label in orderedLabels">
        <gl-label
          :key="label.id"
          class="js-no-trigger"
          :background-color="label.color"
          :title="label.title"
          :description="label.description"
          size="sm"
          :scoped="showScopedLabel(label)"
          @click="filterByLabel(label)"
        />
      </template>
    </div>
    <div
      class="board-card-footer gl-display-flex gl-justify-content-space-between gl-align-items-flex-end"
    >
      <div
        class="gl-display-flex align-items-start flex-wrap-reverse board-card-number-container gl-overflow-hidden js-board-card-number-container"
      >
        <gl-loading-icon v-if="item.isLoading" size="md" class="mt-3" />
        <span
          v-if="item.referencePath"
          class="board-card-number gl-overflow-hidden gl-display-flex gl-mr-3 gl-mt-3"
          :class="{ 'gl-font-base': isEpicBoard }"
        >
          <tooltip-on-truncate
            v-if="itemReferencePath"
            :title="itemReferencePath"
            placement="bottom"
            class="board-item-path gl-text-truncate gl-font-weight-bold"
            >{{ itemReferencePath }}</tooltip-on-truncate
          >
          {{ itemId }}
        </span>
        <span class="board-info-items gl-mt-3 gl-display-inline-block">
          <span v-if="shouldRenderEpicCountables" data-testid="epic-countables">
            <gl-tooltip :target="() => $refs.countBadge" data-testid="epic-countables-tooltip">
              <p v-if="allowSubEpics" class="gl-font-weight-bold gl-m-0">
                {{ __('Epics') }} &#8226;
                <span class="gl-font-weight-normal">
                  <gl-sprintf :message="__('%{openedEpics} open, %{closedEpics} closed')">
                    <template #openedEpics>{{ item.descendantCounts.openedEpics }}</template>
                    <template #closedEpics>{{ item.descendantCounts.closedEpics }}</template>
                  </gl-sprintf>
                </span>
              </p>
              <p class="gl-font-weight-bold gl-m-0">
                {{ __('Issues') }} &#8226;
                <span class="gl-font-weight-normal">
                  <gl-sprintf :message="__('%{openedIssues} open, %{closedIssues} closed')">
                    <template #openedIssues>{{ item.descendantCounts.openedIssues }}</template>
                    <template #closedIssues>{{ item.descendantCounts.closedIssues }}</template>
                  </gl-sprintf>
                </span>
              </p>
              <p class="gl-font-weight-bold gl-m-0">
                {{ __('Total weight') }} &#8226;
                <span class="gl-font-weight-normal" data-testid="epic-countables-total-weight">
                  {{ totalWeight }}
                </span>
              </p>
            </gl-tooltip>

            <gl-tooltip
              v-if="shouldRenderEpicProgress"
              :target="() => $refs.progressBadge"
              data-testid="epic-progress-tooltip"
            >
              <p class="gl-font-weight-bold gl-m-0">
                {{ __('Progress') }} &#8226;
                <span class="gl-font-weight-normal" data-testid="epic-progress-tooltip-content">
                  <gl-sprintf
                    :message="__('%{completedWeight} of %{totalWeight} weight completed')"
                  >
                    <template #completedWeight>{{
                      item.descendantWeightSum.closedIssues
                    }}</template>
                    <template #totalWeight>{{ totalWeight }}</template>
                  </gl-sprintf>
                </span>
              </p>
            </gl-tooltip>

            <span ref="countBadge" class="issue-count-badge board-card-info gl-mr-0 gl-pr-0">
              <span v-if="allowSubEpics" class="gl-mr-3">
                <gl-icon name="epic" />
                {{ totalEpicsCount }}
              </span>
              <span class="gl-mr-3" data-testid="epic-countables-counts-issues">
                <gl-icon name="issues" />
                {{ totalIssuesCount }}
              </span>
              <span class="gl-mr-3" data-testid="epic-countables-weight-issues">
                <gl-icon name="weight" />
                {{ totalWeight }}
              </span>
            </span>

            <span
              v-if="shouldRenderEpicProgress"
              ref="progressBadge"
              class="issue-count-badge board-card-info gl-pl-0"
            >
              <span class="gl-mr-3" data-testid="epic-progress">
                <gl-icon name="progress" />
                {{ totalProgress }}%
              </span>
            </span>
          </span>
          <span v-if="!isEpicBoard">
            <issue-due-date
              v-if="item.dueDate"
              :date="item.dueDate"
              :closed="item.closed || Boolean(item.closedAt)"
            />
            <issue-time-estimate v-if="item.timeEstimate" :estimate="item.timeEstimate" />
            <issue-card-weight
              v-if="validIssueWeight(item)"
              :weight="item.weight"
              @click="filterByWeight(item.weight)"
            />
          </span>
        </span>
      </div>
      <div class="board-card-assignee gl-display-flex">
        <user-avatar-link
          v-for="assignee in cappedAssignees"
          :key="assignee.id"
          :link-href="assigneeUrl(assignee)"
          :img-alt="avatarUrlTitle(assignee)"
          :img-src="avatarUrl(assignee)"
          :img-size="24"
          class="js-no-trigger"
          tooltip-placement="bottom"
        >
          <span class="js-assignee-tooltip">
            <span class="gl-font-weight-bold gl-display-block">{{ __('Assignee') }}</span>
            {{ assignee.name }}
            <span class="text-white-50">@{{ assignee.username }}</span>
          </span>
        </user-avatar-link>
        <span
          v-if="shouldRenderCounter"
          v-gl-tooltip
          :title="assigneeCounterTooltip"
          class="avatar-counter"
          data-placement="bottom"
          >{{ assigneeCounterLabel }}</span
        >
      </div>
    </div>
  </div>
</template>
