<script>
import {
  GlButton,
  GlButtonGroup,
  GlLabel,
  GlTooltip,
  GlIcon,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { isListDraggable } from '~/boards/boards_util';
import { isScopedLabel, parseBoolean } from '~/lib/utils/common_utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { n__, s__, __ } from '~/locale';
import sidebarEventHub from '~/sidebar/event_hub';
import Tracking from '~/tracking';
import { formatDate } from '~/lib/utils/datetime_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import AccessorUtilities from '~/lib/utils/accessor';
import { inactiveId, LIST, ListType, toggleFormEventPrefix } from '../constants';
import eventHub from '../eventhub';
import ItemCount from './item_count.vue';

export default {
  i18n: {
    newIssue: __('New issue'),
    newEpic: s__('Boards|New epic'),
    listSettings: __('List settings'),
    expand: s__('Boards|Expand'),
    collapse: s__('Boards|Collapse'),
  },
  components: {
    GlButtonGroup,
    GlButton,
    GlLabel,
    GlTooltip,
    GlIcon,
    GlSprintf,
    ItemCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin(), glFeatureFlagMixin()],
  inject: {
    weightFeatureAvailable: {
      default: false,
    },
    scopedLabelsAvailable: {
      default: false,
    },
    currentUserId: {
      default: null,
    },
    canCreateEpic: {
      default: false,
    },
    isEpicBoard: {
      default: false,
    },
    disabled: {
      default: true,
    },
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    isSwimlanesHeader: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['activeId', 'filterParams', 'boardId']),
    ...mapGetters(['isSwimlanesOn']),
    isLoggedIn() {
      return Boolean(this.currentUserId);
    },
    listType() {
      return this.list.listType;
    },
    listAssignee() {
      return this.list?.assignee?.username || '';
    },
    listTitle() {
      return this.list?.label?.description || this.list?.assignee?.name || this.list.title || '';
    },
    isIterationList() {
      return this.listType === ListType.iteration;
    },
    showListHeaderButton() {
      return !this.disabled && this.listType !== ListType.closed;
    },
    showMilestoneListDetails() {
      return this.listType === ListType.milestone && this.list.milestone && this.showListDetails;
    },
    showAssigneeListDetails() {
      return this.listType === ListType.assignee && this.showListDetails;
    },
    showIterationListDetails() {
      return this.isIterationList && this.showListDetails;
    },
    showListDetails() {
      return !this.list.collapsed || !this.isSwimlanesHeader;
    },
    showListHeaderActions() {
      if (this.isLoggedIn) {
        return this.isNewIssueShown || this.isNewEpicShown || this.isSettingsShown;
      }
      return false;
    },
    countIcon() {
      return 'issues';
    },
    itemsTooltipLabel() {
      return n__(`%d issue`, `%d issues`, this.boardList?.issuesCount);
    },
    chevronTooltip() {
      return this.list.collapsed ? this.$options.i18n.expand : this.$options.i18n.collapse;
    },
    chevronIcon() {
      return this.list.collapsed ? 'chevron-right' : 'chevron-down';
    },
    isNewIssueShown() {
      return (this.listType === ListType.backlog || this.showListHeaderButton) && !this.isEpicBoard;
    },
    isNewEpicShown() {
      return this.isEpicBoard && this.canCreateEpic && this.listType !== ListType.closed;
    },
    isSettingsShown() {
      return (
        this.listType !== ListType.backlog && this.showListHeaderButton && !this.list.collapsed
      );
    },
    uniqueKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `boards.${this.boardId}.${this.listType}.${this.list.id}`;
    },
    collapsedTooltipTitle() {
      return this.listTitle || this.listAssignee;
    },
    headerStyle() {
      return { borderTopColor: this.list?.label?.color };
    },
    userCanDrag() {
      return !this.disabled && isListDraggable(this.list);
    },
    isLoading() {
      return this.$apollo.queries.boardList.loading;
    },
    totalWeight() {
      return this.boardList?.totalWeight;
    },
    canShowTotalWeight() {
      return this.weightFeatureAvailable && !this.isLoading;
    },
  },
  apollo: {
    boardList: {
      query: listQuery,
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      context: {
        isSingleRequest: true,
      },
      skip() {
        return this.isEpicBoard;
      },
    },
  },
  created() {
    const localCollapsed = parseBoolean(localStorage.getItem(`${this.uniqueKey}.collapsed`));
    if ((!this.isLoggedIn || this.isEpicBoard) && localCollapsed) {
      this.toggleListCollapsed({ listId: this.list.id, collapsed: true });
    }
  },
  methods: {
    ...mapActions(['updateList', 'setActiveId', 'toggleListCollapsed']),
    openSidebarSettings() {
      if (this.activeId === inactiveId) {
        sidebarEventHub.$emit('sidebar.closeAll');
      }

      this.setActiveId({ id: this.list.id, sidebarType: LIST });

      this.track('click_button', { label: 'list_settings' });
    },
    showScopedLabels(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },

    showNewIssueForm() {
      if (this.isSwimlanesOn) {
        eventHub.$emit('open-unassigned-lane');
        this.$nextTick(() => {
          eventHub.$emit(`${toggleFormEventPrefix.issue}${this.list.id}`);
        });
      } else {
        eventHub.$emit(`${toggleFormEventPrefix.issue}${this.list.id}`);
      }
    },
    showNewEpicForm() {
      eventHub.$emit(`${toggleFormEventPrefix.epic}${this.list.id}`);
    },
    toggleExpanded() {
      const collapsed = !this.list.collapsed;
      this.toggleListCollapsed({ listId: this.list.id, collapsed });

      if (!this.isLoggedIn) {
        this.addToLocalStorage();
      } else {
        this.updateListFunction();
      }

      // When expanding/collapsing, the tooltip on the caret button sometimes stays open.
      // Close all tooltips manually to prevent dangling tooltips.
      this.$root.$emit(BV_HIDE_TOOLTIP);

      this.track('click_toggle_button', {
        label: 'toggle_list',
        property: collapsed ? 'closed' : 'open',
      });
    },
    addToLocalStorage() {
      if (AccessorUtilities.canUseLocalStorage()) {
        localStorage.setItem(`${this.uniqueKey}.collapsed`, this.list.collapsed);
      }
    },
    updateListFunction() {
      this.updateList({ listId: this.list.id, collapsed: this.list.collapsed });
    },
    /**
     * TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/344619
     * This method also exists as a utility function in ee/../iterations/utils.js
     * Remove the duplication when the EE code is separated from this compoment.
     */
    getIterationPeriod({ startDate, dueDate }) {
      const start = formatDate(startDate, 'mmm d, yyyy', true);
      const due = formatDate(dueDate, 'mmm d, yyyy', true);
      return `${start} - ${due}`;
    },
  },
};
</script>

<template>
  <header
    :class="{
      'gl-h-full': list.collapsed,
      'board-inner gl-rounded-top-left-base gl-rounded-top-right-base gl-bg-gray-50': isSwimlanesHeader,
    }"
    :style="headerStyle"
    class="board-header gl-relative"
    data-qa-selector="board_list_header"
    data-testid="board-list-header"
  >
    <h3
      :class="{
        'gl-cursor-grab': userCanDrag,
        'gl-py-3 gl-h-full': list.collapsed && !isSwimlanesHeader,
        'gl-border-b-0': list.collapsed || isSwimlanesHeader,
        'gl-py-2': list.collapsed && isSwimlanesHeader,
        'gl-flex-direction-column': list.collapsed,
      }"
      class="board-title gl-m-0 gl-display-flex gl-align-items-center gl-font-base gl-px-3 gl-h-9"
    >
      <gl-button
        v-gl-tooltip.hover
        :aria-label="chevronTooltip"
        :title="chevronTooltip"
        :icon="chevronIcon"
        class="board-title-caret no-drag gl-cursor-pointer gl-hover-bg-gray-50"
        :class="{ 'gl-mt-1': list.collapsed, 'gl-mr-2': !list.collapsed }"
        category="tertiary"
        size="small"
        data-testid="board-title-caret"
        @click="toggleExpanded"
      />
      <!-- EE start -->

      <a
        v-if="showAssigneeListDetails"
        :href="list.assignee.webUrl"
        class="user-avatar-link js-no-trigger"
        :class="{
          'gl-mt-3 gl-rotate-90': list.collapsed,
        }"
      >
        <img
          v-gl-tooltip.hover.bottom
          :title="listAssignee"
          :alt="list.assignee.name"
          :src="list.assignee.avatarUrl"
          class="avatar s20"
          height="20"
          width="20"
        />
      </a>
      <!-- EE end -->
      <div
        class="board-title-text"
        :class="{
          'gl-display-none': list.collapsed && isSwimlanesHeader,
          'gl-flex-grow-0 gl-my-3 gl-mx-0': list.collapsed,
          'gl-flex-grow-1': !list.collapsed,
          'gl-rotate-90': list.collapsed,
        }"
      >
        <!-- EE start -->
        <span
          v-if="listType !== 'label'"
          v-gl-tooltip.hover
          :class="{
            'gl-display-block': list.collapsed || listType === 'milestone',
          }"
          :title="listTitle"
          class="board-title-main-text gl-text-truncate"
        >
          {{ listTitle }}
        </span>
        <span
          v-if="listType === 'assignee'"
          v-show="!list.collapsed"
          class="gl-ml-2 gl-font-weight-normal gl-text-secondary"
        >
          @{{ listAssignee }}
        </span>
        <!-- EE end -->
        <gl-label
          v-if="listType === 'label'"
          v-gl-tooltip.hover.bottom
          :background-color="list.label.color"
          :description="list.label.description"
          :scoped="showScopedLabels(list.label)"
          :size="list.collapsed ? 'sm' : ''"
          :title="list.label.title"
        />
      </div>

      <!-- EE start -->
      <span
        v-if="isSwimlanesHeader && list.collapsed"
        ref="collapsedInfo"
        aria-hidden="true"
        class="board-header-collapsed-info-icon gl-cursor-pointer gl-text-secondary gl-hover-text-gray-900"
      >
        <gl-icon name="information" />
      </span>
      <gl-tooltip v-if="isSwimlanesHeader && list.collapsed" :target="() => $refs.collapsedInfo">
        <div class="gl-font-weight-bold gl-pb-2">{{ collapsedTooltipTitle }}</div>
        <div v-if="list.maxIssueCount !== 0">
          •
          <gl-sprintf :message="__('%{issuesSize} with a limit of %{maxIssueCount}')">
            <template #issuesSize>{{ itemsTooltipLabel }}</template>
            <template #maxIssueCount>{{ list.maxIssueCount }}</template>
          </gl-sprintf>
        </div>
        <div v-else>• {{ itemsTooltipLabel }}</div>
        <div v-if="weightFeatureAvailable && !isLoading">
          •
          <gl-sprintf :message="__('%{totalWeight} total weight')">
            <template #totalWeight>{{ totalWeight }}</template>
          </gl-sprintf>
        </div>
      </gl-tooltip>
      <!-- EE end -->

      <div
        class="issue-count-badge gl-display-inline-flex gl-pr-2 no-drag gl-text-secondary"
        data-testid="issue-count-badge"
        :class="{
          'gl-display-none!': list.collapsed && isSwimlanesHeader,
          'gl-p-0': list.collapsed,
        }"
      >
        <span class="gl-display-inline-flex" :class="{ 'gl-rotate-90': list.collapsed }">
          <gl-tooltip :target="() => $refs.itemCount" :title="itemsTooltipLabel" />
          <span ref="itemCount" class="gl-display-inline-flex gl-align-items-center">
            <gl-icon class="gl-mr-2" :name="countIcon" :size="16" />
            <item-count
              v-if="!isLoading"
              :items-size="isEpicBoard ? list.epicsCount : boardList.issuesCount"
              :max-issue-count="list.maxIssueCount"
            />
          </span>
          <!-- EE start -->
          <template v-if="canShowTotalWeight">
            <gl-tooltip :target="() => $refs.weightTooltip" :title="weightCountToolTip" />
            <span ref="weightTooltip" class="gl-display-inline-flex gl-ml-3" data-testid="weight">
              <gl-icon class="gl-mr-2" name="weight" />
              {{ totalWeight }}
            </span>
          </template>
          <!-- EE end -->
        </span>
      </div>
      <gl-button-group v-if="showListHeaderActions" class="board-list-button-group gl-pl-2">
        <gl-button
          v-if="isNewIssueShown"
          v-show="!list.collapsed"
          ref="newIssueBtn"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.newIssue"
          :title="$options.i18n.newIssue"
          class="no-drag"
          icon="plus"
          @click="showNewIssueForm"
        />

        <gl-button
          v-if="isNewEpicShown"
          v-show="!list.collapsed"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.newEpic"
          :title="$options.i18n.newEpic"
          class="no-drag"
          icon="plus"
          @click="showNewEpicForm"
        />

        <gl-button
          v-if="isSettingsShown"
          ref="settingsBtn"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.listSettings"
          class="no-drag"
          :title="$options.i18n.listSettings"
          icon="settings"
          @click="openSidebarSettings"
        />
      </gl-button-group>
    </h3>
  </header>
</template>
