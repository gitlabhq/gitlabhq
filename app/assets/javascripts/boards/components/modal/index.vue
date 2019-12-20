<script>
/* global ListIssue */
import { GlLoadingIcon } from '@gitlab/ui';
import { urlParamsToObject } from '~/lib/utils/common_utils';
import boardsStore from '~/boards/stores/boards_store';
import ModalHeader from './header.vue';
import ModalList from './list.vue';
import ModalFooter from './footer.vue';
import EmptyState from './empty_state.vue';
import ModalStore from '../../stores/modal_store';

export default {
  components: {
    EmptyState,
    ModalHeader,
    ModalList,
    ModalFooter,
    GlLoadingIcon,
  },
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
  created() {
    this.page = 1;
  },
  methods: {
    loadIssues(clearIssues = false) {
      if (!this.showAddIssuesModal) return false;

      return boardsStore
        .getBacklog({
          ...urlParamsToObject(this.filter.path),
          page: this.page,
          per: this.perPage,
        })
        .then(res => res.data)
        .then(data => {
          if (clearIssues) {
            this.issues = [];
          }

          data.issues.forEach(issueObj => {
            const issue = new ListIssue(issueObj);
            const foundSelectedIssue = ModalStore.findSelectedIssue(issue);
            issue.selected = Boolean(foundSelectedIssue);

            this.issues.push(issue);
          });

          this.loadingNewPage = false;

          if (!this.issuesCount) {
            this.issuesCount = data.size;
          }
        })
        .catch(() => {
          // TODO: handle request error
        });
    },
  },
};
</script>
<template>
  <div
    v-if="showAddIssuesModal"
    class="add-issues-modal d-flex position-fixed position-top-0 position-bottom-0 position-left-0 position-right-0 h-100"
  >
    <div class="add-issues-container d-flex flex-column m-auto rounded">
      <modal-header
        :project-id="projectId"
        :milestone-path="milestonePath"
        :label-path="labelPath"
      />
      <modal-list
        v-if="!loading && showList && !filterLoading"
        :issue-link-base="issueLinkBase"
        :root-path="rootPath"
        :empty-state-svg="emptyStateSvg"
      />
      <empty-state
        v-if="showEmptyState"
        :new-issue-path="newIssuePath"
        :empty-state-svg="emptyStateSvg"
      />
      <section v-if="loading || filterLoading" class="add-issues-list d-flex h-100 text-center">
        <div class="add-issues-list-loading w-100 align-self-center">
          <gl-loading-icon size="md" />
        </div>
      </section>
      <modal-footer />
    </div>
  </div>
</template>
