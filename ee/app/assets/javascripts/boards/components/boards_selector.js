import Vue from 'vue';
import { throttle } from 'underscore';
import BoardForm from './board_form.vue';

(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  const Store = gl.issueBoards.BoardsStore;

  Store.createNewListDropdownData();

  gl.issueBoards.BoardsSelector = Vue.extend({
    name: 'boards-selector',
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
        scrollFadeInitialized: false,
        boards: [],
        state: Store.state,
        throttledSetScrollFade: throttle(this.setScrollFade, this.throttleDuration),
        contentClientHeight: 0,
        maxPosition: 0,
      };
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
          gl.boardService.allBoards()
            .then(res => res.data)
            .then((json) => {
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
    },
    created() {
      this.state.currentBoard = this.currentBoard;
    },
  });
})();
