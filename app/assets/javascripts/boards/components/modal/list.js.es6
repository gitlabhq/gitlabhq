/* global Vue */
/* global ListIssue */
(() => {
  const Store = gl.issueBoards.BoardsStore;

  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  gl.issueBoards.ModalList = Vue.extend({
    data() {
      return Store.modal;
    },
    watch: {
      activeTab() {
        this.$nextTick(() => {
          this.destroyMasonry();
          this.initMasonry();
        });
      },
    },
    computed: {
      loading() {
        return this.issues.length === 0;
      },
    },
    methods: {
      toggleIssue(issue) {
        issue.selected = !issue.selected;
      },
      showIssue(issue) {
        if (this.activeTab === 'all') return true;

        return issue.selected;
      },
      initMasonry() {
        listMasonry = new Masonry(this.$refs.list, {
          transitionDuration: 0,
        });
      },
      destroyMasonry() {
        if (listMasonry) {
          listMasonry.destroy();
        }
      }
    },
    mounted() {
      gl.boardService.getBacklog()
        .then((res) => {
          const data = res.json();

          data.forEach((issueObj) => {
            this.issues.push(new ListIssue(issueObj));
          });

          this.$nextTick(() => {
            this.initMasonry();
          });
        });
    },
    destroyed() {
      this.issues = [];
      this.destroyMasonry();
    },
    components: {
      'issue-card-inner': gl.issueBoards.IssueCardInner,
    },
    template: `
      <section class="add-issues-list">
        <i
          class="fa fa-spinner fa-spin"
          v-if="loading"></i>
        <div
          class="add-issues-list-columns list-unstyled"
          ref="list"
          v-show="!loading">
          <div
            v-for="issue in issues"
            v-if="showIssue(issue)"
            class="card-parent">
            <div
              class="card"
              :class="{ 'is-active': issue.selected }"
              @click="toggleIssue(issue)">
              <issue-card-inner
                :issue="issue"
                :issue-link-base="'/'">
              </issue-card-inner>
            </div>
          </div>
        </div>
      </section>
    `,
  });
})();
