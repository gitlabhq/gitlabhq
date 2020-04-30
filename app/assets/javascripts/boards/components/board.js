import $ from 'jquery';
import Sortable from 'sortablejs';
import Vue from 'vue';
import { GlButtonGroup, GlDeprecatedButton, GlLabel, GlTooltip } from '@gitlab/ui';
import isWipLimitsOn from 'ee_else_ce/boards/mixins/is_wip_limits';
import { s__, __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import AccessorUtilities from '../../lib/utils/accessor';
import BoardBlankState from './board_blank_state.vue';
import BoardDelete from './board_delete';
import BoardList from './board_list.vue';
import IssueCount from './issue_count.vue';
import boardsStore from '../stores/boards_store';
import { getBoardSortableDefaultOptions, sortableEnd } from '../mixins/sortable_default_options';
import { ListType } from '../constants';
import { isScopedLabel } from '~/lib/utils/common_utils';

/**
 * Please don't edit this file, have a look at:
 * ./board_column.vue
 * https://gitlab.com/gitlab-org/gitlab/-/issues/212300
 *
 * This file here will be deleted soon
 * @deprecated
 */
export default Vue.extend({
  components: {
    BoardBlankState,
    BoardDelete,
    BoardList,
    Icon,
    GlButtonGroup,
    IssueCount,
    GlDeprecatedButton,
    GlLabel,
    GlTooltip,
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
    // Does not do anything but is used
    // to support the API of the new board_column.vue
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      detailIssue: boardsStore.detail,
      filter: boardsStore.filter,
    };
  },
  computed: {
    isLoggedIn() {
      return Boolean(gon.current_user_id);
    },
    showListHeaderButton() {
      return (
        !this.disabled && this.list.type !== ListType.closed && this.list.type !== ListType.blank
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
  template: '#js-board-template',
});
