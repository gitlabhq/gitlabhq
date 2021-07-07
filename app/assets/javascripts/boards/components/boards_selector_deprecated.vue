<script>
import {
  GlLoadingIcon,
  GlSearchBoxByType,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { throttle } from 'lodash';
import { mapGetters, mapState } from 'vuex';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import httpStatusCodes from '~/lib/utils/http_status';

import groupQuery from '../graphql/group_boards.query.graphql';
import projectQuery from '../graphql/project_boards.query.graphql';

import boardsStore from '../stores/boards_store';
import BoardForm from './board_form.vue';

const MIN_BOARDS_TO_VIEW_RECENT = 10;

export default {
  name: 'BoardsSelector',
  components: {
    BoardForm,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    currentBoard: {
      type: Object,
      required: true,
    },
    throttleDuration: {
      type: Number,
      default: 200,
      required: false,
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
    labelsWebUrl: {
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
  },
  data() {
    return {
      hasScrollFade: false,
      loadingBoards: 0,
      loadingRecentBoards: false,
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
    ...mapState(['boardType']),
    ...mapGetters(['isGroupBoard']),
    parentType() {
      return this.boardType;
    },
    loading() {
      return this.loadingRecentBoards || Boolean(this.loadingBoards);
    },
    currentPage() {
      return this.state.currentPage;
    },
    filteredBoards() {
      return this.boards.filter((board) =>
        board.name.toLowerCase().includes(this.filterTerm.toLowerCase()),
      );
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
  },
  created() {
    boardsStore.setCurrentBoard(this.currentBoard);
  },
  methods: {
    showPage(page) {
      boardsStore.showPage(page);
    },
    cancel() {
      this.showPage('');
    },
    loadBoards(toggleDropdown = true) {
      if (toggleDropdown && this.boards.length > 0) {
        return;
      }

      this.$apollo.addSmartQuery('boards', {
        variables() {
          return { fullPath: this.state.endpoints.fullPath };
        },
        query() {
          return this.isGroupBoard ? groupQuery : projectQuery;
        },
        loadingKey: 'loadingBoards',
        update(data) {
          if (!data?.[this.parentType]) {
            return [];
          }
          return data[this.parentType].boards.edges.map(({ node }) => ({
            id: getIdFromGraphQLId(node.id),
            name: node.name,
          }));
        },
      });

      this.loadingRecentBoards = true;
      boardsStore
        .recentBoards()
        .then((res) => {
          this.recentBoards = res.data;
        })
        .catch((err) => {
          /**
           *  If user is unauthorized we'd still want to resolve the
           *  request to display all boards.
           */
          if (err?.response?.status === httpStatusCodes.UNAUTHORIZED) {
            this.recentBoards = []; // recent boards are empty
            return;
          }
          throw err;
        })
        .then(() => this.$nextTick()) // Wait for boards list in DOM
        .then(() => {
          this.setScrollFade();
        })
        .catch(() => {})
        .finally(() => {
          this.loadingRecentBoards = false;
        });
    },
    isScrolledUp() {
      const { content } = this.$refs;

      if (!content) {
        return false;
      }

      const currentPosition = this.contentClientHeight + content.scrollTop;

      return currentPosition < this.maxPosition;
    },
    initScrollFade() {
      const { content } = this.$refs;

      if (!content) {
        return;
      }

      this.scrollFadeInitialized = true;

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
  <div class="boards-switcher js-boards-selector gl-mr-3">
    <span class="boards-selector-wrapper js-boards-selector-wrapper">
      <gl-dropdown
        data-qa-selector="boards_dropdown"
        toggle-class="dropdown-menu-toggle js-dropdown-toggle"
        menu-class="flex-column dropdown-extended-height"
        :text="board.name"
        @show="loadBoards"
      >
        <p class="gl-new-dropdown-header-top" @mousedown.prevent>
          {{ s__('IssueBoards|Switch board') }}
        </p>
        <gl-search-box-by-type ref="searchBox" v-model="filterTerm" class="m-2" />

        <div
          v-if="!loading"
          ref="content"
          data-qa-selector="boards_dropdown_content"
          class="dropdown-content flex-fill"
          @scroll.passive="throttledSetScrollFade"
        >
          <gl-dropdown-item
            v-show="filteredBoards.length === 0"
            class="gl-pointer-events-none text-secondary"
          >
            {{ s__('IssueBoards|No matching boards found') }}
          </gl-dropdown-item>

          <gl-dropdown-section-header v-if="showRecentSection">
            {{ __('Recent') }}
          </gl-dropdown-section-header>

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

          <gl-dropdown-divider v-if="showRecentSection" />

          <gl-dropdown-section-header v-if="showRecentSection">
            {{ __('All') }}
          </gl-dropdown-section-header>

          <gl-dropdown-item
            v-for="otherBoard in filteredBoards"
            :key="otherBoard.id"
            class="js-dropdown-item"
            :href="`${boardBaseUrl}/${otherBoard.id}`"
          >
            {{ otherBoard.name }}
          </gl-dropdown-item>

          <gl-dropdown-item v-if="hasMissingBoards" class="no-pointer-events">
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

        <gl-loading-icon v-if="loading" size="sm" />

        <div v-if="canAdminBoard">
          <gl-dropdown-divider />

          <gl-dropdown-item
            v-if="multipleIssueBoardsAvailable"
            v-gl-modal-directive="'board-config-modal'"
            data-qa-selector="create_new_board_button"
            @click.prevent="showPage('new')"
          >
            {{ s__('IssueBoards|Create new board') }}
          </gl-dropdown-item>

          <gl-dropdown-item
            v-if="showDelete"
            v-gl-modal-directive="'board-config-modal'"
            class="text-danger js-delete-board"
            @click.prevent="showPage('delete')"
          >
            {{ s__('IssueBoards|Delete board') }}
          </gl-dropdown-item>
        </div>
      </gl-dropdown>

      <board-form
        v-if="currentPage"
        :labels-path="labelsPath"
        :labels-web-url="labelsWebUrl"
        :project-id="projectId"
        :group-id="groupId"
        :can-admin-board="canAdminBoard"
        :scoped-issue-board-feature-enabled="scopedIssueBoardFeatureEnabled"
        :weights="weights"
        :enable-scoped-labels="enabledScopedLabels"
        :current-board="currentBoard"
        :current-page="state.currentPage"
        @cancel="cancel"
      />
    </span>
  </div>
</template>
