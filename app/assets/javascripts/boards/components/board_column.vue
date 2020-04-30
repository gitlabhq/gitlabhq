<script>
import $ from 'jquery';
import Sortable from 'sortablejs';
import { GlButtonGroup, GlDeprecatedButton, GlLabel, GlTooltip, GlIcon } from '@gitlab/ui';
import isWipLimitsOn from 'ee_else_ce/boards/mixins/is_wip_limits';
import { s__, __, sprintf } from '~/locale';
import Tooltip from '~/vue_shared/directives/tooltip';
import EmptyComponent from '~/vue_shared/components/empty_component';
import AccessorUtilities from '../../lib/utils/accessor';
import BoardBlankState from './board_blank_state.vue';
import BoardDelete from './board_delete';
import BoardList from './board_list.vue';
import IssueCount from './issue_count.vue';
import boardsStore from '../stores/boards_store';
import { getBoardSortableDefaultOptions, sortableEnd } from '../mixins/sortable_default_options';
import { ListType } from '../constants';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    BoardPromotionState: EmptyComponent,
    BoardBlankState,
    BoardDelete,
    BoardList,
    GlButtonGroup,
    IssueCount,
    GlDeprecatedButton,
    GlLabel,
    GlTooltip,
    GlIcon,
  },
  directives: {
    Tooltip,
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
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
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
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      detailIssue: boardsStore.detail,
      filter: boardsStore.filter,
      weightFeatureAvailable: false,
    };
  },
  computed: {
    isLoggedIn() {
      return Boolean(gon.current_user_id);
    },
    showListHeaderButton() {
      return (
        !this.disabled &&
        this.list.type !== ListType.closed &&
        this.list.type !== ListType.blank &&
        this.list.type !== ListType.promotion
      );
    },
    issuesTooltip() {
      const { issuesSize } = this.list;

      return sprintf(__('%{issuesSize} issues'), { issuesSize });
    },
    // Only needed to make karma pass.
    weightCountToolTip() {}, // eslint-disable-line vue/return-in-computed-property
    caretTooltip() {
      return this.list.isExpanded ? s__('Boards|Collapse') : s__('Boards|Expand');
    },
    isNewIssueShown() {
      return this.list.type === ListType.backlog || this.showListHeaderButton;
    },
    isSettingsShown() {
      return (
        this.list.type !== ListType.backlog &&
        this.showListHeaderButton &&
        this.list.isExpanded &&
        this.isWipLimitsOn
      );
    },
    showBoardListAndBoardInfo() {
      return this.list.type !== ListType.blank && this.list.type !== ListType.promotion;
    },
    uniqueKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `boards.${this.boardId}.${this.list.type}.${this.list.id}`;
    },
  },
  watch: {
    filter: {
      handler() {
        this.list.page = 1;
        this.list.getIssues(true).catch(() => {
          // TODO: handle request error
        });
      },
      deep: true,
    },
  },
  mounted() {
    const instance = this;

    const sortableOptions = getBoardSortableDefaultOptions({
      disabled: this.disabled,
      group: 'boards',
      draggable: '.is-draggable',
      handle: '.js-board-handle',
      onEnd(e) {
        sortableEnd();

        const sortable = this;

        if (e.newIndex !== undefined && e.oldIndex !== e.newIndex) {
          const order = sortable.toArray();
          const list = boardsStore.findList('id', parseInt(e.item.dataset.id, 10));

          instance.$nextTick(() => {
            boardsStore.moveList(list, order);
          });
        }
      },
    });

    Sortable.create(this.$el.parentNode, sortableOptions);
  },
  created() {
    if (
      this.list.isExpandable &&
      AccessorUtilities.isLocalStorageAccessSafe() &&
      !this.isLoggedIn
    ) {
      const isCollapsed = localStorage.getItem(`${this.uniqueKey}.expanded`) === 'false';

      this.list.isExpanded = !isCollapsed;
    }
  },
  methods: {
    showScopedLabels(label) {
      return boardsStore.scopedLabels.enabled && isScopedLabel(label);
    },

    showNewIssueForm() {
      this.$refs['board-list'].showIssueForm = !this.$refs['board-list'].showIssueForm;
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
        $('.tooltip').tooltip('hide');
      }
    },
  },
};
</script>

<template>
  <div
    :class="{
      'is-draggable': !list.preset,
      'is-expandable': list.isExpandable,
      'is-collapsed': !list.isExpanded,
      'board-type-assignee': list.type === 'assignee',
    }"
    :data-id="list.id"
    class="board h-100 px-2 align-top ws-normal"
    data-qa-selector="board_list"
  >
    <div class="board-inner d-flex flex-column position-relative h-100 rounded">
      <header
        :class="{
          'has-border': list.label && list.label.color,
          'position-relative': list.isExpanded,
          'position-absolute position-top-0 position-left-0 w-100 h-100': !list.isExpanded,
        }"
        :style="{ borderTopColor: list.label && list.label.color ? list.label.color : null }"
        class="board-header"
        data-qa-selector="board_list_header"
      >
        <h3
          :class="{
            'user-can-drag': !disabled && !list.preset,
            'border-bottom-0': !list.isExpanded,
          }"
          class="board-title m-0 d-flex js-board-handle"
        >
          <div
            v-if="list.isExpandable"
            v-tooltip=""
            :aria-label="caretTooltip"
            :title="caretTooltip"
            aria-hidden="true"
            class="board-title-caret no-drag"
            data-placement="bottom"
            @click="toggleExpanded"
          >
            <i
              :class="{ 'fa-caret-right': list.isExpanded, 'fa-caret-down': !list.isExpanded }"
              class="fa fa-fw"
            ></i>
          </div>
          <!-- The following is only true in EE and if it is a milestone -->
          <span
            v-if="list.type === 'milestone' && list.milestone"
            aria-hidden="true"
            class="append-right-5 milestone-icon"
          >
            <gl-icon name="timer" />
          </span>

          <a
            v-if="list.type === 'assignee'"
            :href="list.assignee.path"
            class="user-avatar-link js-no-trigger"
          >
            <img
              :alt="list.assignee.name"
              :src="list.assignee.avatar"
              class="avatar s20 has-tooltip"
              height="20"
              width="20"
            />
          </a>
          <div class="board-title-text">
            <span
              v-if="list.type !== 'label'"
              :class="{
                'has-tooltip': !['backlog', 'closed'].includes(list.type),
                'd-block': list.type === 'milestone',
              }"
              :title="(list.label && list.label.description) || list.title || ''"
              class="board-title-main-text block-truncated"
              data-container="body"
            >
              {{ list.title }}
            </span>
            <span
              v-if="list.type === 'assignee'"
              :title="(list.assignee && list.assignee.username) || ''"
              class="board-title-sub-text prepend-left-5 has-tooltip"
            >
              @{{ list.assignee.username }}
            </span>
            <gl-label
              v-if="list.type === 'label'"
              :background-color="list.label.color"
              :description="list.label.description"
              :scoped="showScopedLabels(list.label)"
              :size="!list.isExpanded ? 'sm' : ''"
              :title="list.label.title"
              tooltip-placement="bottom"
            />
          </div>
          <board-delete
            v-if="canAdminList && !list.preset && list.id"
            :list="list"
            inline-template="true"
          >
            <button
              :class="{ 'd-none': !list.isExpanded }"
              :aria-label="__(`Delete list`)"
              class="board-delete no-drag p-0 border-0 has-tooltip float-right"
              data-placement="bottom"
              title="Delete list"
              type="button"
              @click.stop="deleteBoard"
            >
              <i aria-hidden="true" data-hidden="true" class="fa fa-trash"></i>
            </button>
          </board-delete>
          <div
            v-if="showBoardListAndBoardInfo"
            class="issue-count-badge pr-0 no-drag text-secondary"
          >
            <span class="d-inline-flex">
              <gl-tooltip :target="() => $refs.issueCount" :title="issuesTooltip" />
              <span ref="issueCount" class="issue-count-badge-count">
                <gl-icon class="mr-1" name="issues" />
                <issue-count :issues-size="list.issuesSize" :max-issue-count="list.maxIssueCount" />
              </span>
              <!-- The following is only true in EE. -->
              <template v-if="weightFeatureAvailable">
                <gl-tooltip :target="() => $refs.weightTooltip" :title="weightCountToolTip" />
                <span ref="weightTooltip" class="d-inline-flex ml-2">
                  <gl-icon class="mr-1" name="weight" />
                  {{ list.totalWeight }}
                </span>
              </template>
            </span>
          </div>
          <gl-button-group
            v-if="isNewIssueShown || isSettingsShown"
            class="board-list-button-group pl-2"
          >
            <gl-deprecated-button
              v-if="isNewIssueShown"
              ref="newIssueBtn"
              :class="{
                'd-none': !list.isExpanded,
                'rounded-right': isNewIssueShown && !isSettingsShown,
              }"
              :aria-label="__(`New issue`)"
              class="issue-count-badge-add-button no-drag"
              type="button"
              @click="showNewIssueForm"
            >
              <i aria-hidden="true" data-hidden="true" class="fa fa-plus"></i>
            </gl-deprecated-button>
            <gl-tooltip :target="() => $refs.newIssueBtn">{{ __('New Issue') }}</gl-tooltip>

            <gl-deprecated-button
              v-if="isSettingsShown"
              ref="settingsBtn"
              :aria-label="__(`List settings`)"
              class="no-drag rounded-right js-board-settings-button"
              title="List settings"
              type="button"
              @click="openSidebarSettings"
            >
              <gl-icon name="settings" />
            </gl-deprecated-button>
            <gl-tooltip :target="() => $refs.settingsBtn">{{ __('List settings') }}</gl-tooltip>
          </gl-button-group>
        </h3>
      </header>
      <board-list
        v-if="showBoardListAndBoardInfo"
        ref="board-list"
        :disabled="disabled"
        :group-id="groupId || null"
        :issue-link-base="issueLinkBase"
        :issues="list.issues"
        :list="list"
        :loading="list.loading"
        :root-path="rootPath"
      />
      <board-blank-state v-if="canAdminList && list.id === 'blank'" />

      <!-- Will be only available in EE -->
      <board-promotion-state v-if="list.id === 'promotion'" />
    </div>
  </div>
</template>
