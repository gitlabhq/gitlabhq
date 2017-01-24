/* global Vue */
/* global ListIssue */
/* global Masonry */
(() => {
  let listMasonry;
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
      issues: {
        handler() {
          if (this.activeTab === 'selected') {
            this.$nextTick(() => {
              listMasonry.layout();
            });
          }
        },
        deep: true,
      }
    },
    computed: {
      loading() {
        return this.issues.length === 0;
      },
      selectedCount() {
        return Store.modalSelectedCount();
      },
    },
    methods: {
      toggleIssue(issueObj) {
        const issue = issueObj;

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
      },
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
        <div
          class="add-issues-list-loading"
          v-if="loading">
          <i class="fa fa-spinner fa-spin"></i>
        </div>
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
              <span
                v-if="issue.selected"
                class="issue-card-selected">
                <i class="fa fa-check"></i>
              </span>
            </div>
          </div>
        </div>
        <p
          class="all-issues-selected-empty"
          v-if="activeTab == 'selected' && selectedCount == 0">
          You don't have any issues selected, <a href="#" @click="activeTab = 'all'">select some</a>.
        </p>
      </section>
    `,
  });
})();
