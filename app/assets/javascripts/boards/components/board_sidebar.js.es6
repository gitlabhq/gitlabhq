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
            this.issuableContext = new IssuableContext(this.currentUser);
            this.milestoneSelect = new MilestoneSelect();
            this.dueDateSelect = new gl.DueDateSelectors();
            this.labelsSelect = new LabelsSelect();
            this.sidebar = new Sidebar();
            this.subscription = new Subscription('.subscription');
          });
        } else {
          $('.right-sidebar').getNiceScroll().remove();

          delete this.issuableContext;
          delete this.milestoneSelect;
          delete this.dueDateSelect;
          delete this.labelsSelect;
          delete this.sidebar;
          delete this.subscription;
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
