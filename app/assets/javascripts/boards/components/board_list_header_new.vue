<script>
import { mapActions, mapState } from 'vuex';
import {
  GlButton,
  GlButtonGroup,
  GlLabel,
  GlTooltip,
  GlIcon,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import AccessorUtilities from '../../lib/utils/accessor';
import IssueCount from './issue_count.vue';
import eventHub from '../eventhub';
import sidebarEventHub from '~/sidebar/event_hub';
import { inactiveId, LIST, ListType } from '../constants';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlButtonGroup,
    GlButton,
    GlLabel,
    GlTooltip,
    GlIcon,
    GlSprintf,
    IssueCount,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    isSwimlanesHeader: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  inject: {
    boardId: {
      default: '',
    },
    weightFeatureAvailable: {
      default: false,
    },
    scopedLabelsAvailable: {
      default: false,
    },
    currentUserId: {
      default: null,
    },
  },
  computed: {
    ...mapState(['activeId']),
    isLoggedIn() {
      return Boolean(this.currentUserId);
    },
    listType() {
      return this.list.type;
    },
    listAssignee() {
      return this.list?.assignee?.username || '';
    },
    listTitle() {
      return this.list?.label?.description || this.list.title || '';
    },
    showListHeaderButton() {
      return (
        !this.disabled &&
        this.listType !== ListType.closed &&
        this.listType !== ListType.blank &&
        this.listType !== ListType.promotion
      );
    },
    showMilestoneListDetails() {
      return (
        this.list.type === ListType.milestone &&
        this.list.milestone &&
        (this.list.isExpanded || !this.isSwimlanesHeader)
      );
    },
    showAssigneeListDetails() {
      return (
        this.list.type === ListType.assignee && (this.list.isExpanded || !this.isSwimlanesHeader)
      );
    },
    issuesCount() {
      return this.list.issuesSize;
    },
    issuesTooltipLabel() {
      return n__(`%d issue`, `%d issues`, this.issuesCount);
    },
    chevronTooltip() {
      return this.list.isExpanded ? s__('Boards|Collapse') : s__('Boards|Expand');
    },
    chevronIcon() {
      return this.list.isExpanded ? 'chevron-right' : 'chevron-down';
    },
    isNewIssueShown() {
      return this.listType === ListType.backlog || this.showListHeaderButton;
    },
    isSettingsShown() {
      return (
        this.listType !== ListType.backlog && this.showListHeaderButton && this.list.isExpanded
      );
    },
    showBoardListAndBoardInfo() {
      return this.listType !== ListType.blank && this.listType !== ListType.promotion;
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
  },
  methods: {
    ...mapActions(['updateList', 'setActiveId']),
    openSidebarSettings() {
      if (this.activeId === inactiveId) {
        sidebarEventHub.$emit('sidebar.closeAll');
      }

      this.setActiveId({ id: this.list.id, sidebarType: LIST });
    },
    showScopedLabels(label) {
      return this.scopedLabelsAvailable && isScopedLabel(label);
    },

    showNewIssueForm() {
      eventHub.$emit(`toggle-issue-form-${this.list.id}`);
    },
    toggleExpanded() {
      this.list.isExpanded = !this.list.isExpanded;

      if (!this.isLoggedIn) {
        this.addToLocalStorage();
      } else {
        this.updateListFunction();
      }

      // When expanding/collapsing, the tooltip on the caret button sometimes stays open.
      // Close all tooltips manually to prevent dangling tooltips.
      this.$root.$emit('bv::hide::tooltip');
    },
    addToLocalStorage() {
      if (AccessorUtilities.isLocalStorageAccessSafe()) {
        localStorage.setItem(`${this.uniqueKey}.expanded`, this.list.isExpanded);
      }
    },
    updateListFunction() {
      this.updateList({ listId: this.list.id, collapsed: !this.list.isExpanded });
    },
  },
};
</script>

<template>
  <header
    :class="{
      'has-border': list.label && list.label.color,
      'gl-h-full': !list.isExpanded,
      'board-inner gl-rounded-top-left-base gl-rounded-top-right-base': isSwimlanesHeader,
    }"
    :style="headerStyle"
    class="board-header gl-relative"
    data-qa-selector="board_list_header"
    data-testid="board-list-header"
  >
    <h3
      :class="{
        'user-can-drag': !disabled && !list.preset,
        'gl-py-3 gl-h-full': !list.isExpanded && !isSwimlanesHeader,
        'gl-border-b-0': !list.isExpanded || isSwimlanesHeader,
        'gl-py-2': !list.isExpanded && isSwimlanesHeader,
        'gl-flex-direction-column': !list.isExpanded,
      }"
      class="board-title gl-m-0 gl-display-flex gl-align-items-center gl-font-base gl-px-3 js-board-handle"
    >
      <gl-button
        v-if="list.isExpandable"
        v-gl-tooltip.hover
        :aria-label="chevronTooltip"
        :title="chevronTooltip"
        :icon="chevronIcon"
        class="board-title-caret no-drag gl-cursor-pointer"
        category="tertiary"
        size="small"
        @click="toggleExpanded"
      />
      <!-- EE start -->
      <span
        v-if="showMilestoneListDetails"
        aria-hidden="true"
        class="milestone-icon"
        :class="{
          'gl-mt-3 gl-rotate-90': !list.isExpanded,
          'gl-mr-2': list.isExpanded,
        }"
      >
        <gl-icon name="timer" />
      </span>

      <a
        v-if="showAssigneeListDetails"
        :href="list.assignee.path"
        class="user-avatar-link js-no-trigger"
        :class="{
          'gl-mt-3 gl-rotate-90': !list.isExpanded,
        }"
      >
        <img
          v-gl-tooltip.hover.bottom
          :title="listAssignee"
          :alt="list.assignee.name"
          :src="list.assignee.avatar"
          class="avatar s20"
          height="20"
          width="20"
        />
      </a>
      <!-- EE end -->
      <div
        class="board-title-text"
        :class="{
          'gl-display-none': !list.isExpanded && isSwimlanesHeader,
          'gl-flex-grow-0 gl-my-3 gl-mx-0': !list.isExpanded,
          'gl-flex-grow-1': list.isExpanded,
        }"
      >
        <!-- EE start -->
        <span
          v-if="listType !== 'label'"
          v-gl-tooltip.hover
          :class="{
            'gl-display-block': !list.isExpanded || listType === 'milestone',
          }"
          :title="listTitle"
          class="board-title-main-text gl-text-truncate"
        >
          {{ list.title }}
        </span>
        <span
          v-if="listType === 'assignee'"
          v-show="list.isExpanded"
          class="gl-ml-2 gl-font-weight-normal gl-text-gray-500"
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
          :size="!list.isExpanded ? 'sm' : ''"
          :title="list.label.title"
        />
      </div>

      <!-- EE start -->
      <span
        v-if="isSwimlanesHeader && !list.isExpanded"
        ref="collapsedInfo"
        aria-hidden="true"
        class="board-header-collapsed-info-icon gl-cursor-pointer gl-text-gray-500"
      >
        <gl-icon name="information" />
      </span>
      <gl-tooltip v-if="isSwimlanesHeader && !list.isExpanded" :target="() => $refs.collapsedInfo">
        <div class="gl-font-weight-bold gl-pb-2">{{ collapsedTooltipTitle }}</div>
        <div v-if="list.maxIssueCount !== 0">
          •
          <gl-sprintf :message="__('%{issuesSize} with a limit of %{maxIssueCount}')">
            <template #issuesSize>{{ issuesTooltipLabel }}</template>
            <template #maxIssueCount>{{ list.maxIssueCount }}</template>
          </gl-sprintf>
        </div>
        <div v-else>• {{ issuesTooltipLabel }}</div>
        <div v-if="weightFeatureAvailable">
          •
          <gl-sprintf :message="__('%{totalWeight} total weight')">
            <template #totalWeight>{{ list.totalWeight }}</template>
          </gl-sprintf>
        </div>
      </gl-tooltip>
      <!-- EE end -->

      <div
        v-if="showBoardListAndBoardInfo"
        class="issue-count-badge gl-display-inline-flex gl-pr-0 no-drag gl-text-gray-500"
        :class="{
          'gl-display-none!': !list.isExpanded && isSwimlanesHeader,
          'gl-p-0': !list.isExpanded,
        }"
      >
        <span class="gl-display-inline-flex">
          <gl-tooltip :target="() => $refs.issueCount" :title="issuesTooltipLabel" />
          <span ref="issueCount" class="issue-count-badge-count">
            <gl-icon class="gl-mr-2" name="issues" />
            <issue-count :issues-size="issuesCount" :max-issue-count="list.maxIssueCount" />
          </span>
          <!-- EE start -->
          <template v-if="weightFeatureAvailable">
            <gl-tooltip :target="() => $refs.weightTooltip" :title="weightCountToolTip" />
            <span ref="weightTooltip" class="gl-display-inline-flex gl-ml-3">
              <gl-icon class="gl-mr-2" name="weight" />
              {{ list.totalWeight }}
            </span>
          </template>
          <!-- EE end -->
        </span>
      </div>
      <gl-button-group
        v-if="isNewIssueShown || isSettingsShown"
        class="board-list-button-group pl-2"
      >
        <gl-button
          v-if="isNewIssueShown"
          v-show="list.isExpanded"
          ref="newIssueBtn"
          v-gl-tooltip.hover
          :aria-label="__('New issue')"
          :title="__('New issue')"
          class="issue-count-badge-add-button no-drag"
          icon="plus"
          @click="showNewIssueForm"
        />

        <gl-button
          v-if="isSettingsShown"
          ref="settingsBtn"
          v-gl-tooltip.hover
          :aria-label="__('List settings')"
          class="no-drag js-board-settings-button"
          :title="__('List settings')"
          icon="settings"
          @click="openSidebarSettings"
        />
        <gl-tooltip :target="() => $refs.settingsBtn">{{ __('List settings') }}</gl-tooltip>
      </gl-button-group>
    </h3>
  </header>
</template>
