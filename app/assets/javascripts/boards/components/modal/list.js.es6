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
          this.$nextTick(() => {
            if (this.activeTab === 'selected') {
              listMasonry.layout();
            }
          });
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
      this.initMasonry();
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
      </section>
    `,
  });
})();
