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
import { mapActions, mapState } from 'vuex';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { n__, s__ } from '~/locale';
import sidebarEventHub from '~/sidebar/event_hub';
import AccessorUtilities from '../../lib/utils/accessor';
import { inactiveId, LIST, ListType } from '../constants';
import eventHub from '../eventhub';
import boardsStore from '../stores/boards_store';
import IssueCount from './item_count.vue';

// This component is being replaced in favor of './board_list_header.vue' for GraphQL boards

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
  inject: {
    currentUserId: {
      default: null,
    },
    boardId: {
      default: '',
    },
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
  data() {
    return {
      weightFeatureAvailable: false,
    };
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
      return !this.disabled && this.listType !== ListType.closed;
    },
    showMilestoneListDetails() {
      return this.list.type === 'milestone' && this.list.milestone && this.showListDetails;
    },
    showAssigneeListDetails() {
      return this.list.type === 'assignee' && this.showListDetails;
    },
    showIterationListDetails() {
      return this.listType === ListType.iteration && this.showListDetails;
    },
    showListDetails() {
      return this.list.isExpanded || !this.isSwimlanesHeader;
    },
    showListHeaderActions() {
      if (this.isLoggedIn) {
        return this.isNewIssueShown || this.isSettingsShown;
      }
      return false;
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
    uniqueKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `boards.${this.boardId}.${this.listType}.${this.list.id}`;
    },
    collapsedTooltipTitle() {
      return this.listTitle || this.listAssignee;
    },
  },
  methods: {
    ...mapActions(['setActiveId']),
    openSidebarSettings() {
      if (this.activeId === inactiveId) {
        sidebarEventHub.$emit('sidebar.closeAll');
      }

      this.setActiveId({ id: this.list.id, sidebarType: LIST });
    },
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },

    showNewIssueForm() {
      eventHub.$emit(`toggle-issue-form-${this.list.id}`);
    },
    toggleExpanded() {
      // eslint-disable-next-line vue/no-mutating-props
      this.list.isExpanded = !this.list.isExpanded;

      if (!this.isLoggedIn) {
        this.addToLocalStorage();
      } else {
        this.updateListFunction();
      }

      // When expanding/collapsing, the tooltip on the caret button sometimes stays open.
      // Close all tooltips manually to prevent dangling tooltips.
      this.$root.$emit(BV_HIDE_TOOLTIP);
    },
    addToLocalStorage() {
      if (AccessorUtilities.isLocalStorageAccessSafe()) {
        localStorage.setItem(`${this.uniqueKey}.expanded`, this.list.isExpanded);
      }
    },
    updateListFunction() {
      this.list.update();
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
    :style="{ borderTopColor: list.label && list.label.color ? list.label.color : null }"
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
      <!-- The following is only true in EE and if it is a milestone -->
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

      <span
        v-if="showIterationListDetails"
        aria-hidden="true"
        :class="{
          'gl-mt-3 gl-rotate-90': !list.isExpanded,
          'gl-mr-2': list.isExpanded,
        }"
      >
        <gl-icon name="iteration" />
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
      <div
        class="board-title-text"
        :class="{
          'gl-display-none': !list.isExpanded && isSwimlanesHeader,
          'gl-flex-grow-0 gl-my-3 gl-mx-0': !list.isExpanded,
          'gl-flex-grow-1': list.isExpanded,
        }"
      >
        <span
          v-if="list.type !== 'label'"
          v-gl-tooltip.hover
          :class="{
            'gl-display-block': !list.isExpanded || list.type === 'milestone',
          }"
          :title="listTitle"
          class="board-title-main-text gl-text-truncate"
        >
          {{ list.title }}
        </span>
        <span
          v-if="list.type === 'assignee'"
          class="gl-ml-2 gl-font-weight-normal gl-text-gray-500"
          :class="{ 'gl-display-none': !list.isExpanded }"
        >
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
        class="board-header-collapsed-info-icon gl-mt-2 gl-cursor-pointer gl-text-gray-500"
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

      <div
        class="issue-count-badge gl-display-inline-flex gl-pr-0 no-drag text-secondary"
        :class="{
          'gl-display-none!': !list.isExpanded && isSwimlanesHeader,
          'gl-p-0': !list.isExpanded,
        }"
      >
        <span class="gl-display-inline-flex">
          <gl-tooltip :target="() => $refs.issueCount" :title="issuesTooltipLabel" />
          <span ref="issueCount" class="issue-count-badge-count">
            <gl-icon class="gl-mr-2" name="issues" />
            <issue-count :items-size="issuesCount" :max-issue-count="list.maxIssueCount" />
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
      <gl-button-group v-if="showListHeaderActions" class="board-list-button-group pl-2">
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
