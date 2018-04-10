/* global ListIssue */

import Vue from 'vue';
import queryData from '~/boards/utils/query_data';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import './header';
import './list';
import './footer';
import './empty_state';
import ModalStore from '../../stores/modal_store';

gl.issueBoards.IssuesModal = Vue.extend({
  props: {
    newIssuePath: {
      type: String,
      required: true,
    },
    emptyStateSvg: {
      type: String,
      required: true,
    },
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    labelPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return ModalStore.store;
  },
  watch: {
    page() {
      this.loadIssues();
    },
    showAddIssuesModal() {
      if (this.showAddIssuesModal && !this.issues.length) {
        this.loading = true;
        const loadingDone = () => {
          this.loading = false;
        };

        this.loadIssues()
          .then(loadingDone)
          .catch(loadingDone);
      } else if (!this.showAddIssuesModal) {
        this.issues = [];
        this.selectedIssues = [];
        this.issuesCount = false;
      }
    },
    filter: {
      handler() {
        if (this.$el.tagName) {
          this.page = 1;
          this.filterLoading = true;
          const loadingDone = () => {
            this.filterLoading = false;
          };

          this.loadIssues(true)
            .then(loadingDone)
            .catch(loadingDone);
        }
      },
      deep: true,
    },
  },
  methods: {
    loadIssues(clearIssues = false) {
      if (!this.showAddIssuesModal) return false;

      return gl.boardService.getBacklog(queryData(this.filter.path, {
        page: this.page,
        per: this.perPage,
      }))
      .then(res => res.data)
      .then((data) => {
        if (clearIssues) {
          this.issues = [];
        }

        data.issues.forEach((issueObj) => {
          const issue = new ListIssue(issueObj);
          const foundSelectedIssue = ModalStore.findSelectedIssue(issue);
          issue.selected = !!foundSelectedIssue;

          this.issues.push(issue);
        });

        this.loadingNewPage = false;

        if (!this.issuesCount) {
          this.issuesCount = data.size;
        }
      }).catch(() => {
        // TODO: handle request error
      });
    },
  },
  computed: {
    showList() {
      if (this.activeTab === 'selected') {
        return this.selectedIssues.length > 0;
      }

      return this.issuesCount > 0;
    },
    showEmptyState() {
      if (!this.loading && this.issuesCount === 0) {
        return true;
      }

      return this.activeTab === 'selected' && this.selectedIssues.length === 0;
    },
  },
  created() {
    this.page = 1;
  },
  components: {
    'modal-header': gl.issueBoards.ModalHeader,
    'modal-list': gl.issueBoards.ModalList,
    'modal-footer': gl.issueBoards.ModalFooter,
    'empty-state': gl.issueBoards.ModalEmptyState,
    loadingIcon,
  },
  template: `
    <div
      class="add-issues-modal"
      v-if="showAddIssuesModal">
      <div class="add-issues-container">
        <modal-header
          :project-id="projectId"
          :milestone-path="milestonePath"
          :label-path="labelPath">
        </modal-header>
        <modal-list
          :issue-link-base="issueLinkBase"
          :root-path="rootPath"
          :empty-state-svg="emptyStateSvg"
          v-if="!loading && showList && !filterLoading"></modal-list>
        <empty-state
          v-if="showEmptyState"
          :new-issue-path="newIssuePath"
          :empty-state-svg="emptyStateSvg"></empty-state>
        <section
          class="add-issues-list text-center"
          v-if="loading || filterLoading">
          <div class="add-issues-list-loading">
            <loading-icon />
          </div>
        </section>
        <modal-footer></modal-footer>
      </div>
    </div>
  `,
});
