<script>
import {
  GlAvatar,
  GlButton,
  GlButtonGroup,
  GlLabel,
  GlTooltip,
  GlIcon,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isListDraggable } from '~/boards/boards_util';
import { isScopedLabel, parseBoolean } from '~/lib/utils/common_utils';
import { fetchPolicies } from '~/lib/graphql';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { n__, s__ } from '~/locale';
import Tracking from '~/tracking';
import { TYPE_ISSUE } from '~/issues/constants';
import setActiveBoardItemMutation from 'ee_else_ce/boards/graphql/client/set_active_board_item.mutation.graphql';
import AccessorUtilities from '~/lib/utils/accessor';
import {
  ListType,
  updateListQueries,
  toggleCollapsedMutations,
  listsDeferredQuery,
} from 'ee_else_ce/boards/constants';
import { setError } from '../graphql/cache_updates';
import ItemCount from './item_count.vue';

export default {
  i18n: {
    newIssue: s__('Boards|Create new issue'),
    newEpic: s__('Boards|Create new epic'),
    listSettings: s__('Boards|Edit list settings'),
    expand: s__('Boards|Expand'),
    collapse: s__('Boards|Collapse'),
    fetchError: s__(
      "Boards|An error occurred while fetching list's information. Please try again.",
    ),
  },
  components: {
    GlAvatar,
    GlButton,
    GlButtonGroup,
    GlLabel,
    GlTooltip,
    GlIcon,
    GlSprintf,
    ItemCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
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
    issuableType: {
      default: TYPE_ISSUE,
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
    filterParams: {
      type: Object,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  computed: {
    isLoggedIn() {
      return Boolean(this.currentUserId);
    },
    listType() {
      return this.list.listType;
    },
    isLabelList() {
      return this.listType === ListType.label;
    },
    itemsCount() {
      return this.isEpicBoard ? this.list.metadata.epicsCount : this.boardList?.issuesCount;
    },
    boardItemsSizeExceedsMax() {
      return this.list.maxIssueCount > 0 && this.itemsCount > this.list.maxIssueCount;
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
        return (
          (this.isNewIssueShown || this.isNewEpicShown || this.isSettingsShown) &&
          !this.list.collapsed
        );
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
      return this.list.collapsed ? 'chevron-lg-right' : 'chevron-lg-down';
    },
    isNewIssueShown() {
      return (this.listType === ListType.backlog || this.showListHeaderButton) && !this.isEpicBoard;
    },
    isNewEpicShown() {
      return this.isEpicBoard && this.canCreateEpic && this.listType !== ListType.closed;
    },
    isSettingsShown() {
      return (
        this.listType !== ListType.backlog &&
        this.listType !== ListType.closed &&
        !this.list.collapsed
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
    // due to the issues with cache-and-network, we need this hack to check if there is any data for the query in the cache.
    // if we have cached data, we disregard the loading state
    isLoading() {
      return (
        this.$apollo.queries.boardList.loading &&
        !this.$apollo.provider.clients.defaultClient.readQuery({
          query: listsDeferredQuery[this.issuableType].query,
          variables: this.countQueryVariables,
        })
      );
    },
    totalIssueWeight() {
      return this.boardList?.totalIssueWeight;
    },
    canShowTotalWeight() {
      return this.weightFeatureAvailable && !this.isLoading;
    },
    countQueryVariables() {
      return {
        id: this.list.id,
        filters: this.filterParams,
      };
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    boardList: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query() {
        return listsDeferredQuery[this.issuableType].query;
      },
      variables() {
        return this.countQueryVariables;
      },
      error(error) {
        setError({
          error,
          message: this.$options.i18n.fetchError,
        });
      },
    },
  },
  created() {
    const localCollapsed = parseBoolean(localStorage.getItem(`${this.uniqueKey}.collapsed`));
    if ((!this.isLoggedIn || this.isEpicBoard) && localCollapsed) {
      this.updateLocalCollapsedStatus(true);
    }
  },
  methods: {
    openSidebarSettings() {
      this.$apollo.mutate({
        mutation: setActiveBoardItemMutation,
        variables: { boardItem: null, listId: null },
      });
      this.$emit('setActiveList', this.list.id);

      this.track('click_button', { label: 'list_settings' });
    },
    showScopedLabels(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },
    showNewForm() {
      if (this.isSwimlanesHeader) {
        this.$emit('openUnassignedLane');
        this.$nextTick(() => {
          this.$emit('toggleNewForm');
        });
      } else {
        this.$emit('toggleNewForm');
      }
    },
    toggleExpanded() {
      const collapsed = !this.list.collapsed;
      this.updateLocalCollapsedStatus(collapsed);

      if (!this.isLoggedIn) {
        this.addToLocalStorage(collapsed);
      } else {
        this.updateListFunction(collapsed);
      }

      // When expanding/collapsing, the tooltip on the caret button sometimes stays open.
      // Close all tooltips manually to prevent dangling tooltips.
      this.$root.$emit(BV_HIDE_TOOLTIP);

      this.track('click_toggle_button', {
        label: 'toggle_list',
        property: collapsed ? 'closed' : 'open',
      });
    },
    addToLocalStorage(collapsed) {
      if (AccessorUtilities.canUseLocalStorage()) {
        localStorage.setItem(`${this.uniqueKey}.collapsed`, collapsed);
      }
    },
    async updateListFunction(collapsed) {
      try {
        await this.$apollo.mutate({
          mutation: updateListQueries[this.issuableType].mutation,
          variables: {
            listId: this.list.id,
            collapsed,
          },
          optimisticResponse: {
            updateBoardList: {
              __typename: 'UpdateBoardListPayload',
              errors: [],
              list: {
                ...this.list,
                collapsed,
              },
            },
          },
        });
      } catch (error) {
        setError({
          error,
          message: s__('Boards|An error occurred while updating the list. Please try again.'),
        });
      }
    },
    updateLocalCollapsedStatus(collapsed) {
      this.$apollo.mutate({
        mutation: toggleCollapsedMutations[this.issuableType].mutation,
        variables: {
          list: this.list,
          collapsed,
        },
      });
    },
  },
};
</script>

<template>
  <header
    :class="{
      'gl-h-full': list.collapsed,
      'gl-bg-strong': isSwimlanesHeader,
      'gl-rounded-tl-base gl-rounded-tr-base gl-border-4 gl-border-t-solid': isLabelList,
      'gl-rounded-tl-base gl-rounded-tr-base gl-bg-red-50': boardItemsSizeExceedsMax,
    }"
    :style="headerStyle"
    class="board-header gl-relative"
    data-testid="board-list-header"
  >
    <h3
      :class="{
        'gl-cursor-grab': userCanDrag,
        'gl-h-full gl-py-3': list.collapsed && !isSwimlanesHeader,
        'gl-border-b-0': list.collapsed || isSwimlanesHeader,
        'gl-pb-0 gl-pt-2': list.collapsed && isSwimlanesHeader,
        'gl-flex-col': list.collapsed,
        '-gl-mt-2': isLabelList && (!list.collapsed || (list.collapsed && isSwimlanesHeader)),
        'gl-pt-3': isLabelList && list.collapsed && isSwimlanesHeader,
      }"
      class="board-title gl-m-0 gl-flex gl-h-9 gl-items-center gl-px-3 gl-text-base"
    >
      <gl-button
        v-gl-tooltip.hover
        :aria-label="chevronTooltip"
        :title="chevronTooltip"
        :icon="chevronIcon"
        class="board-title-caret no-drag gl-cursor-pointer hover:gl-bg-strong"
        :class="{
          '-gl-mt-1': list.collapsed && isLabelList,
          'gl-mb-2': list.collapsed && isLabelList && !isSwimlanesHeader,
          'gl-mt-1': list.collapsed && !isLabelList,
          'gl-mr-2': !list.collapsed,
        }"
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
          'gl-mt-5 gl-rotate-90': list.collapsed,
        }"
      >
        <gl-avatar
          v-gl-tooltip.hover.bottom
          :title="listAssignee"
          :alt="list.assignee.name"
          :src="list.assignee.avatarUrl"
          :entity-name="list.assignee.name"
          :size="24"
          class="gl-mr-3"
        />
      </a>
      <!-- EE end -->
      <div
        class="board-title-text"
        :class="{
          'gl-hidden': list.collapsed && isSwimlanesHeader,
          'gl-mx-0 gl-my-3 gl-flex-grow-0 gl-rotate-90 gl-py-0': list.collapsed,
          'gl-grow': !list.collapsed,
        }"
      >
        <!-- EE start -->
        <span
          v-if="listType !== 'label'"
          v-gl-tooltip.hover
          :class="{
            '!gl-ml-2': list.collapsed && !showAssigneeListDetails,
            'gl-text-subtle': list.collapsed,
            'gl-block': list.collapsed || listType === 'milestone',
          }"
          :title="listTitle"
          class="board-title-main-text gl-truncate"
        >
          {{ listTitle }}
        </span>
        <span
          v-if="listType === 'assignee'"
          v-show="!list.collapsed"
          class="gl-ml-2 gl-font-normal gl-text-subtle"
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
          :title="list.label.title"
        />
      </div>

      <!-- EE start -->
      <span
        v-if="isSwimlanesHeader && list.collapsed"
        ref="collapsedInfo"
        aria-hidden="true"
        class="board-header-collapsed-info-icon gl-cursor-pointer"
      >
        <gl-icon name="information" variant="subtle" />
      </span>
      <gl-tooltip v-if="isSwimlanesHeader && list.collapsed" :target="() => $refs.collapsedInfo">
        <div class="gl-pb-2 gl-font-bold">{{ collapsedTooltipTitle }}</div>
        <div v-if="list.maxIssueCount !== 0">
          •
          <gl-sprintf :message="__('%{issuesSize} with a limit of %{maxIssueCount}')">
            <template #issuesSize>{{ itemsCount }}</template>
            <template #maxIssueCount>{{ list.maxIssueCount }}</template>
          </gl-sprintf>
        </div>
        <div v-else>• {{ itemsTooltipLabel }}</div>
        <div v-if="weightFeatureAvailable && !isLoading">
          •
          <gl-sprintf :message="__('%{totalIssueWeight} total weight')">
            <template #totalIssueWeight>{{ totalIssueWeight }}</template>
          </gl-sprintf>
        </div>
      </gl-tooltip>
      <!-- EE end -->

      <div
        class="issue-count-badge no-drag gl-inline-flex gl-pr-2 gl-text-sm gl-text-subtle"
        data-testid="issue-count-badge"
        :class="{
          '!gl-hidden': list.collapsed && isSwimlanesHeader,
          'gl-p-0': list.collapsed,
        }"
      >
        <span class="gl-inline-flex" :class="{ 'gl-rotate-90': list.collapsed }">
          <gl-tooltip :target="() => $refs.itemCount" :title="itemsTooltipLabel" />
          <span ref="itemCount" class="gl-inline-flex gl-items-center" data-testid="item-count">
            <gl-icon class="gl-mr-2" :name="countIcon" :size="14" />
            <item-count
              v-if="!isLoading"
              :items-size="itemsCount"
              :max-issue-count="list.maxIssueCount"
            />
          </span>
          <!-- EE start -->
          <template v-if="canShowTotalWeight">
            <gl-tooltip :target="() => $refs.weightTooltip" :title="weightCountToolTip" />
            <span ref="weightTooltip" class="gl-ml-3 gl-inline-flex" data-testid="weight">
              <gl-icon class="gl-mr-2" name="weight" :size="14" />
              {{ totalIssueWeight }}
            </span>
          </template>
          <!-- EE end -->
        </span>
      </div>
      <gl-button-group v-if="showListHeaderActions" class="board-list-button-group gl-pl-2">
        <gl-button
          v-if="isNewIssueShown"
          ref="newIssueBtn"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.newIssue"
          :title="$options.i18n.newIssue"
          size="small"
          icon="plus"
          data-testid="new-issue-btn"
          @click="showNewForm"
        />

        <gl-button
          v-if="isNewEpicShown"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.newEpic"
          :title="$options.i18n.newEpic"
          size="small"
          icon="plus"
          data-testid="new-epic-btn"
          @click="showNewForm"
        />

        <gl-button
          v-if="isSettingsShown"
          ref="settingsBtn"
          v-gl-tooltip.hover
          :aria-label="$options.i18n.listSettings"
          size="small"
          :title="$options.i18n.listSettings"
          icon="settings"
          data-testid="settings-btn"
          @click="openSidebarSettings"
        />
      </gl-button-group>
    </h3>
  </header>
</template>
