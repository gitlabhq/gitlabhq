/* global ListIssue */

import Vue from 'vue';
import bp from '../../../breakpoints';
import ModalStore from '../../stores/modal_store';

gl.issueBoards.ModalList = Vue.extend({
  props: {
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    emptyStateSvg: {
      type: String,
      required: true,
    },
  },
  data() {
    return ModalStore.store;
  },
  watch: {
    activeTab() {
      if (this.activeTab === 'all') {
        ModalStore.purgeUnselectedIssues();
      }
    },
  },
  computed: {
    loopIssues() {
      if (this.activeTab === 'all') {
        return this.issues;
      }

      return this.selectedIssues;
    },
    groupedIssues() {
      const groups = [];
      this.loopIssues.forEach((issue, i) => {
        const index = i % this.columns;

        if (!groups[index]) {
          groups.push([]);
        }

        groups[index].push(issue);
      });

      return groups;
    },
  },
  methods: {
    scrollHandler() {
      const currentPage = Math.floor(this.issues.length / this.perPage);

      if ((this.scrollTop() > this.scrollHeight() - 100) && !this.loadingNewPage
        && currentPage === this.page) {
        this.loadingNewPage = true;
        this.page += 1;
      }
    },
    toggleIssue(e, issue) {
      if (e.target.tagName !== 'A') {
        ModalStore.toggleIssue(issue);
      }
    },
    listHeight() {
      return this.$refs.list.getBoundingClientRect().height;
    },
    scrollHeight() {
      return this.$refs.list.scrollHeight;
    },
    scrollTop() {
      return this.$refs.list.scrollTop + this.listHeight();
    },
    showIssue(issue) {
      if (this.activeTab === 'all') return true;

      const index = ModalStore.selectedIssueIndex(issue);

      return index !== -1;
    },
    setColumnCount() {
      const breakpoint = bp.getBreakpointSize();

      if (breakpoint === 'lg' || breakpoint === 'md') {
        this.columns = 3;
      } else if (breakpoint === 'sm') {
        this.columns = 2;
      } else {
        this.columns = 1;
      }
    },
  },
  mounted() {
    this.scrollHandlerWrapper = this.scrollHandler.bind(this);
    this.setColumnCountWrapper = this.setColumnCount.bind(this);
    this.setColumnCount();

    this.$refs.list.addEventListener('scroll', this.scrollHandlerWrapper);
    window.addEventListener('resize', this.setColumnCountWrapper);
  },
  beforeDestroy() {
    this.$refs.list.removeEventListener('scroll', this.scrollHandlerWrapper);
    window.removeEventListener('resize', this.setColumnCountWrapper);
  },
  components: {
    'issue-card-inner': gl.issueBoards.IssueCardInner,
  },
  template: `
    <section
      class="add-issues-list add-issues-list-columns"
      ref="list">
      <div
        class="empty-state add-issues-empty-state-filter text-center"
        v-if="issuesCount > 0 && issues.length === 0">
        <div
          class="svg-content">
          <img :src="emptyStateSvg"/>
        </div>
        <div class="text-content">
          <h4>
            There are no issues to show.
          </h4>
        </div>
      </div>
      <div
        v-for="group in groupedIssues"
        class="add-issues-list-column">
        <div
          v-for="issue in group"
          v-if="showIssue(issue)"
          class="card-parent">
          <div
            class="card"
            :class="{ 'is-active': issue.selected }"
            @click="toggleIssue($event, issue)">
            <issue-card-inner
              :issue="issue"
              :issue-link-base="issueLinkBase"
              :root-path="rootPath">
            </issue-card-inner>
            <span
              :aria-label="'Issue #' + issue.id + ' selected'"
              aria-checked="true"
              v-if="issue.selected"
              class="issue-card-selected text-center">
              <i class="fa fa-check"></i>
            </span>
          </div>
        </div>
      </div>
    </section>
  `,
});
