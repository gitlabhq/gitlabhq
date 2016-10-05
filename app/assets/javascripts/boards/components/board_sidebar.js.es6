(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardSidebar = Vue.extend({
    data() {
      return {
        detail: Store.detail,
        issue: {}
      };
    },
    computed: {
      showSidebar () {
        return Object.keys(this.issue).length;
      }
    },
    watch: {
      detail: {
        handler () {
          this.issue = this.detail.issue;
        },
        deep: true
      },
      issue () {
        if (this.showSidebar) {
          this.$nextTick(() => {
            new IssuableContext();
            new MilestoneSelect();
            new Sidebar();
          });
        } else {
          $('.right-sidebar').getNiceScroll().remove();
        }
      }
    },
    methods: {
      closeSidebar () {
        this.detail.issue = {};
      }
    }
  });
})();
