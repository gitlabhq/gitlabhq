<script>
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import Icon from '~/vue_shared/components/icon.vue';
import ModalStore from '../../stores/modal_store';
import IssueCardInner from '../issue_card_inner.vue';

export default {
  components: {
    IssueCardInner,
    Icon,
  },
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
  watch: {
    activeTab() {
      if (this.activeTab === 'all') {
        ModalStore.purgeUnselectedIssues();
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
  methods: {
    scrollHandler() {
      const currentPage = Math.floor(this.issues.length / this.perPage);

      if (
        this.scrollTop() > this.scrollHeight() - 100 &&
        !this.loadingNewPage &&
        currentPage === this.page
      ) {
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

      if (breakpoint === 'xl' || breakpoint === 'lg') {
        this.columns = 3;
      } else if (breakpoint === 'md') {
        this.columns = 2;
      } else {
        this.columns = 1;
      }
    },
  },
};
</script>
<template>
  <section ref="list" class="add-issues-list add-issues-list-columns d-flex h-100">
    <div
      v-if="issuesCount > 0 && issues.length === 0"
      class="empty-state add-issues-empty-state-filter text-center"
    >
      <div class="svg-content"><img :src="emptyStateSvg" /></div>
      <div class="text-content">
        <h4>{{ __('There are no issues to show.') }}</h4>
      </div>
    </div>
    <div v-for="(group, index) in groupedIssues" :key="index" class="add-issues-list-column">
      <div v-for="issue in group" v-if="showIssue(issue)" :key="issue.id" class="board-card-parent">
        <div
          :class="{ 'is-active': issue.selected }"
          class="board-card position-relative p-3 rounded"
          @click="toggleIssue($event, issue)"
        >
          <issue-card-inner :issue="issue" :issue-link-base="issueLinkBase" :root-path="rootPath" />
          <icon
            v-if="issue.selected"
            :aria-label="'Issue #' + issue.id + ' selected'"
            name="mobile-issue-close"
            aria-checked="true"
            class="issue-card-selected text-center"
          />
        </div>
      </div>
    </div>
  </section>
</template>
