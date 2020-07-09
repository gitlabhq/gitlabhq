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
import isWipLimitsOn from 'ee_else_ce/boards/mixins/is_wip_limits';
import { n__, s__ } from '~/locale';
import AccessorUtilities from '../../lib/utils/accessor';
import BoardDelete from './board_delete';
import IssueCount from './issue_count.vue';
import boardsStore from '../stores/boards_store';
import eventHub from '../eventhub';
import { ListType } from '../constants';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    BoardDelete,
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
  mixins: [isWipLimitsOn],
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
    boardId: {
      type: String,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSwimlanesHeader: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      weightFeatureAvailable: false,
    };
  },
  computed: {
    isLoggedIn() {
      return Boolean(gon.current_user_id);
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
        this.list.type === 'milestone' &&
        this.list.milestone &&
        (this.list.isExpanded || !this.isSwimlanesHeader)
      );
    },
    showAssigneeListDetails() {
      return this.list.type === 'assignee' && (this.list.isExpanded || !this.isSwimlanesHeader);
    },
    issuesTooltipLabel() {
      const { issuesSize } = this.list;

      return n__(`%d issue`, `%d issues`, issuesSize);
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
        this.listType !== ListType.backlog &&
        this.showListHeaderButton &&
        this.list.isExpanded &&
        this.isWipLimitsOn
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
  },
  methods: {
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },

    showNewIssueForm() {
      eventHub.$emit(`toggle-issue-form-${this.list.id}`);
    },
    toggleExpanded() {
      if (this.list.isExpandable) {
        this.list.isExpanded = !this.list.isExpanded;

        if (AccessorUtilities.isLocalStorageAccessSafe() && !this.isLoggedIn) {
          localStorage.setItem(`${this.uniqueKey}.expanded`, this.list.isExpanded);
        }

        if (this.isLoggedIn) {
          this.list.update();
        }

        // When expanding/collapsing, the tooltip on the caret button sometimes stays open.
        // Close all tooltips manually to prevent dangling tooltips.
        this.$root.$emit('bv::hide::tooltip');
      }
    },
  },
};
</script>

<template>
  <header
    :class="{
      'has-border': list.label && list.label.color,
      'gl-relative': list.isExpanded,
      'gl-h-full': !list.isExpanded,
      'board-inner gl-rounded-top-left-base gl-rounded-top-right-base': isSwimlanesHeader,
    }"
    :style="{ borderTopColor: list.label && list.label.color ? list.label.color : null }"
    class="board-header gl-relative"
    data-qa-selector="board_list_header"
    data-testid="board-list-header"
  >
    <h3
      :class="{
        'user-can-drag': !disabled && !list.preset,
        'gl-py-3': !list.isExpanded && !isSwimlanesHeader,
        'gl-border-b-0': !list.isExpanded || isSwimlanesHeader,
        'gl-py-2': !list.isExpanded && isSwimlanesHeader,
      }"
      class="board-title gl-m-0 gl-display-flex js-board-handle"
    >
      <gl-button
        v-if="list.isExpandable"
        v-gl-tooltip.hover
        :aria-label="chevronTooltip"
        :title="chevronTooltip"
        :icon="chevronIcon"
        class="board-title-caret no-drag gl-cursor-pointer"
        variant="link"
        @click="toggleExpanded"
      />
      <!-- The following is only true in EE and if it is a milestone -->
      <span v-if="showMilestoneListDetails" aria-hidden="true" class="gl-mr-2 milestone-icon">
        <gl-icon name="timer" />
      </span>

      <a
        v-if="showAssigneeListDetails"
        :href="list.assignee.path"
        class="user-avatar-link js-no-trigger"
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
      <div
        class="board-title-text"
        :class="{ 'gl-display-none': !list.isExpanded && isSwimlanesHeader }"
      >
        <span
          v-if="list.type !== 'label'"
          v-gl-tooltip.hover
          :class="{
            'gl-display-inline-block': list.type === 'milestone',
          }"
          :title="listTitle"
          class="board-title-main-text block-truncated"
        >
          {{ list.title }}
        </span>
        <span v-if="list.type === 'assignee'" class="board-title-sub-text gl-ml-2">
          @{{ listAssignee }}
        </span>
        <gl-label
          v-if="list.type === 'label'"
          v-gl-tooltip.hover.bottom
          :background-color="list.label.color"
          :description="list.label.description"
          :scoped="showScopedLabels(list.label)"
          :size="!list.isExpanded ? 'sm' : ''"
          :title="list.label.title"
        />
      </div>

      <span
        v-if="isSwimlanesHeader && !list.isExpanded"
        ref="collapsedInfo"
        aria-hidden="true"
        class="board-header-collapsed-info-icon gl-mt-2 gl-cursor-pointer gl-text-gray-700"
      >
        <gl-icon name="information" />
      </span>
      <gl-tooltip v-if="isSwimlanesHeader && !list.isExpanded" :target="() => $refs.collapsedInfo">
        <div class="gl-font-weight-bold gl-pb-2">{{ collapsedTooltipTitle }}</div>
        <div v-if="list.maxIssueCount !== 0">
          &#8226;
          <gl-sprintf :message="__('%{issuesSize} with a limit of %{maxIssueCount}')">
            <template #issuesSize>{{ issuesTooltipLabel }}</template>
            <template #maxIssueCount>{{ list.maxIssueCount }}</template>
          </gl-sprintf>
        </div>
        <div v-else>&#8226; {{ issuesTooltipLabel }}</div>
        <div v-if="weightFeatureAvailable">
          &#8226;
          <gl-sprintf :message="__('%{totalWeight} total weight')">
            <template #totalWeight>{{ list.totalWeight }}</template>
          </gl-sprintf>
        </div>
      </gl-tooltip>

      <board-delete
        v-if="canAdminList && !list.preset && list.id"
        :list="list"
        inline-template="true"
      >
        <gl-button
          v-gl-tooltip.hover.bottom
          :class="{ 'gl-display-none': !list.isExpanded }"
          :aria-label="__('Delete list')"
          class="board-delete no-drag gl-pr-0 gl-shadow-none! gl-mr-3"
          :title="__('Delete list')"
          icon="remove"
          size="small"
          @click.stop="deleteBoard"
        />
      </board-delete>
      <div
        v-if="showBoardListAndBoardInfo"
        class="issue-count-badge gl-pr-0 no-drag text-secondary"
        :class="{ 'gl-display-none': !list.isExpanded && isSwimlanesHeader }"
      >
        <span class="gl-display-inline-flex">
          <gl-tooltip :target="() => $refs.issueCount" :title="issuesTooltipLabel" />
          <span ref="issueCount" class="issue-count-badge-count">
            <gl-icon class="gl-mr-2" name="issues" />
            <issue-count :issues-size="list.issuesSize" :max-issue-count="list.maxIssueCount" />
          </span>
          <!-- The following is only true in EE. -->
          <template v-if="weightFeatureAvailable">
            <gl-tooltip :target="() => $refs.weightTooltip" :title="weightCountToolTip" />
            <span ref="weightTooltip" class="gl-display-inline-flex gl-ml-3">
              <gl-icon class="gl-mr-2" name="weight" />
              {{ list.totalWeight }}
            </span>
          </template>
        </span>
      </div>
      <gl-button-group
        v-if="isNewIssueShown || isSettingsShown"
        class="board-list-button-group pl-2"
      >
        <gl-button
          v-if="isNewIssueShown"
          ref="newIssueBtn"
          v-gl-tooltip.hover
          :class="{
            'gl-display-none': !list.isExpanded,
          }"
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
