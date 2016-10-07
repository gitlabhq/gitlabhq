(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.BoardSidebar = Vue.extend({
    props: {
      currentUser: Object
    },
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
            new IssuableContext(this.currentUser);
            new MilestoneSelect();
            new DueDateSelect();
            new LabelsSelect();
            new Sidebar();
            new Subscription('.subscription');
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
