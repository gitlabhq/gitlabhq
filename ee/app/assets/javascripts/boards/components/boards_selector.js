import Vue from 'vue';
import $ from 'jquery';
import { throttle } from 'underscore';
import '~/boards/stores/boards_store';
import BoardForm from './board_form.vue';
import AssigneeList from './assignees_list_slector';
import MilestoneList from './milestone_list_selector';

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  const Store = gl.issueBoards.BoardsStore;

  Store.createNewListDropdownData();

  gl.issueBoards.BoardsSelector = Vue.extend({
    name: 'BoardsSelector',
    components: {
      BoardForm,
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
    },
    data() {
      return {
        open: false,
        loading: true,
        hasScrollFade: false,
        hasAssigneesListMounted: false,
        hasMilestoneListMounted: false,
        scrollFadeInitialized: false,
        boards: [],
        state: Store.state,
        throttledSetScrollFade: throttle(this.setScrollFade, this.throttleDuration),
        contentClientHeight: 0,
        maxPosition: 0,
        store: gl.issueBoards.BoardsStore,
      };
    },
    computed: {
      currentPage() {
        return this.state.currentPage;
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
    },
    watch: {
      reload() {
        if (this.reload) {
          this.boards = [];
          this.loading = true;
          this.reload = false;

          this.loadBoards(false);
        }
      },
    },
    created() {
      this.state.currentBoard = this.currentBoard;
      Store.state.assignees = [];
      Store.state.milestones = [];
      $('#js-add-list').on('hide.bs.dropdown', this.handleDropdownHide);
      $('.js-new-board-list-tabs').on('click', this.handleDropdownTabClick);
    },
    methods: {
      showPage(page) {
        this.state.reload = false;
        this.state.currentPage = page;
      },
      toggleDropdown() {
        this.open = !this.open;
      },
      loadBoards(toggleDropdown = true) {
        if (toggleDropdown) {
          this.toggleDropdown();
        }

        if (this.open && !this.boards.length) {
          gl.boardService
            .allBoards()
            .then(res => res.data)
            .then(json => {
              this.loading = false;
              this.boards = json;
            })
            .then(() => this.$nextTick()) // Wait for boards list in DOM
            .then(this.setScrollFade)
            .catch(() => {
              this.loading = false;
            });
        }
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
      handleDropdownHide(e) {
        const $currTarget = $(e.currentTarget);
        if ($currTarget.data('preventClose')) {
          e.preventDefault();
        }
        $currTarget.removeData('preventClose');
      },
      handleDropdownTabClick(e) {
        const $addListEl = $('#js-add-list');
        $addListEl.data('preventClose', true);
        if (e.target.dataset.action === 'tab-assignees' &&
            !this.hasAssigneesListMounted) {
          this.assigneeList = AssigneeList();
          this.hasAssigneesListMounted = true;
        }

        if (e.target.dataset.action === 'tab-milestones' && !this.hasMilestoneListMounted) {
          this.milstoneList = MilestoneList();
          this.hasMilestoneListMounted = true;
        }
      },
    },
  });
})();
