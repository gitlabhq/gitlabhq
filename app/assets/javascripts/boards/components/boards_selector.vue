<script>
import { throttle } from 'underscore';
import {
  GlLoadingIcon,
  GlSearchBoxByType,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownHeader,
  GlDropdownItem,
} from '@gitlab/ui';

import Icon from '~/vue_shared/components/icon.vue';
import httpStatusCodes from '~/lib/utils/http_status';
import boardsStore from '../stores/boards_store';
import BoardForm from './board_form.vue';

const MIN_BOARDS_TO_VIEW_RECENT = 10;

export default {
  name: 'BoardsSelector',
  components: {
    Icon,
    BoardForm,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownHeader,
    GlDropdownItem,
  },
  props: {
    currentBoard: {
      type: Object,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    throttleDuration: {
      type: Number,
      default: 200,
    },
    boardBaseUrl: {
      type: String,
      required: true,
    },
    hasMissingBoards: {
      type: Boolean,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    multipleIssueBoardsAvailable: {
      type: Boolean,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    groupId: {
      type: Number,
      required: true,
    },
    scopedIssueBoardFeatureEnabled: {
      type: Boolean,
      required: true,
    },
    weights: {
      type: Array,
      required: true,
    },
    enabledScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    scopedLabelsDocumentationLink: {
      type: String,
      required: false,
      default: '#',
    },
  },
  data() {
    return {
      loading: true,
      hasScrollFade: false,
      scrollFadeInitialized: false,
      boards: [],
      recentBoards: [],
      state: boardsStore.state,
      throttledSetScrollFade: throttle(this.setScrollFade, this.throttleDuration),
      contentClientHeight: 0,
      maxPosition: 0,
      store: boardsStore,
      filterTerm: '',
    };
  },
  computed: {
    currentPage() {
      return this.state.currentPage;
    },
    filteredBoards() {
      return this.boards.filter(board =>
        board.name.toLowerCase().includes(this.filterTerm.toLowerCase()),
      );
    },
    reload: {
      get() {
        return this.state.reload;
      },
      set(newValue) {
        this.state.reload = newValue;
      },
    },
    board() {
      return this.state.currentBoard;
    },
    showDelete() {
      return this.boards.length > 1;
    },
    scrollFadeClass() {
      return {
        'fade-out': !this.hasScrollFade,
      };
    },
    showRecentSection() {
      return (
        this.recentBoards.length &&
        this.boards.length > MIN_BOARDS_TO_VIEW_RECENT &&
        !this.filterTerm.length
      );
    },
  },
  watch: {
    filteredBoards() {
      this.scrollFadeInitialized = false;
      this.$nextTick(this.setScrollFade);
    },
    reload() {
      if (this.reload) {
        this.boards = [];
        this.recentBoards = [];
        this.loading = true;
        this.reload = false;

        this.loadBoards(false);
      }
    },
  },
  created() {
    boardsStore.setCurrentBoard(this.currentBoard);
  },
  methods: {
    showPage(page) {
      boardsStore.showPage(page);
    },
    loadBoards(toggleDropdown = true) {
      if (toggleDropdown && this.boards.length > 0) {
        return;
      }

      const recentBoardsPromise = new Promise((resolve, reject) =>
        boardsStore
          .recentBoards()
          .then(resolve)
          .catch(err => {
            /**
             *  If user is unauthorized we'd still want to resolve the
             *  request to display all boards.
             */
            if (err.response.status === httpStatusCodes.UNAUTHORIZED) {
              resolve({ data: [] }); // recent boards are empty
              return;
            }
            reject(err);
          }),
      );

      Promise.all([boardsStore.allBoards(), recentBoardsPromise])
        .then(([allBoards, recentBoards]) => [allBoards.data, recentBoards.data])
        .then(([allBoardsJson, recentBoardsJson]) => {
          this.loading = false;
          this.boards = allBoardsJson;
          this.recentBoards = recentBoardsJson;
        })
        .then(() => this.$nextTick()) // Wait for boards list in DOM
        .then(() => {
          this.setScrollFade();
        })
        .catch(() => {
          this.loading = false;
        });
    },
    isScrolledUp() {
      const { content } = this.$refs;
      const currentPosition = this.contentClientHeight + content.scrollTop;

      return content && currentPosition < this.maxPosition;
    },
    initScrollFade() {
      this.scrollFadeInitialized = true;

      const { content } = this.$refs;

      this.contentClientHeight = content.clientHeight;
      this.maxPosition = content.scrollHeight;
    },
    setScrollFade() {
      if (!this.scrollFadeInitialized) this.initScrollFade();

      this.hasScrollFade = this.isScrolledUp();
    },
  },
};
</script>

<template>
  <div class="boards-switcher js-boards-selector append-right-10">
    <span class="boards-selector-wrapper js-boards-selector-wrapper">
      <gl-dropdown
        data-qa-selector="boards_dropdown"
        toggle-class="dropdown-menu-toggle js-dropdown-toggle"
        menu-class="flex-column dropdown-extended-height"
        :text="board.name"
        @show="loadBoards"
      >
        <div>
          <div class="dropdown-title mb-0" @mousedown.prevent>
            {{ s__('IssueBoards|Switch board') }}
          </div>
        </div>

        <gl-dropdown-header class="mt-0">
          <gl-search-box-by-type ref="searchBox" v-model="filterTerm" />
        </gl-dropdown-header>

        <div
          v-if="!loading"
          ref="content"
          data-qa-selector="boards_dropdown_content"
          class="dropdown-content flex-fill"
          @scroll.passive="throttledSetScrollFade"
        >
          <gl-dropdown-item
            v-show="filteredBoards.length === 0"
            class="no-pointer-events text-secondary"
          >
            {{ s__('IssueBoards|No matching boards found') }}
          </gl-dropdown-item>

          <h6 v-if="showRecentSection" class="dropdown-bold-header my-0">
            {{ __('Recent') }}
          </h6>

          <template v-if="showRecentSection">
            <gl-dropdown-item
              v-for="recentBoard in recentBoards"
              :key="`recent-${recentBoard.id}`"
              class="js-dropdown-item"
              :href="`${boardBaseUrl}/${recentBoard.id}`"
            >
              {{ recentBoard.name }}
            </gl-dropdown-item>
          </template>

          <hr v-if="showRecentSection" class="my-1" />

          <h6 v-if="showRecentSection" class="dropdown-bold-header my-0">
            {{ __('All') }}
          </h6>

          <gl-dropdown-item
            v-for="otherBoard in filteredBoards"
            :key="otherBoard.id"
            class="js-dropdown-item"
            :href="`${boardBaseUrl}/${otherBoard.id}`"
          >
            {{ otherBoard.name }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="hasMissingBoards" class="small unclickable">
            {{
              s__(
                'IssueBoards|Some of your boards are hidden, activate a license to see them again.',
              )
            }}
          </gl-dropdown-item>
        </div>

        <div
          v-show="filteredBoards.length > 0"
          class="dropdown-content-faded-mask"
          :class="scrollFadeClass"
        ></div>

        <gl-loading-icon v-if="loading" />

        <div v-if="canAdminBoard">
          <gl-dropdown-divider />

          <gl-dropdown-item
            v-if="multipleIssueBoardsAvailable"
            data-qa-selector="create_new_board_button"
            @click.prevent="showPage('new')"
          >
            {{ s__('IssueBoards|Create new board') }}
          </gl-dropdown-item>

          <gl-dropdown-item
            v-if="showDelete"
            class="text-danger js-delete-board"
            @click.prevent="showPage('delete')"
          >
            {{ s__('IssueBoards|Delete board') }}
          </gl-dropdown-item>
        </div>
      </gl-dropdown>

      <board-form
        v-if="currentPage"
        :milestone-path="milestonePath"
        :labels-path="labelsPath"
        :project-id="projectId"
        :group-id="groupId"
        :can-admin-board="canAdminBoard"
        :scoped-issue-board-feature-enabled="scopedIssueBoardFeatureEnabled"
        :weights="weights"
        :enable-scoped-labels="enabledScopedLabels"
        :scoped-labels-documentation-link="scopedLabelsDocumentationLink"
      />
    </span>
  </div>
</template>
