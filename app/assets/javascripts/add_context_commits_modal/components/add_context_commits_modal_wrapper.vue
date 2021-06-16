<script>
import { GlModal, GlTabs, GlTab, GlSearchBoxByType, GlSprintf } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import ReviewTabContainer from '~/add_context_commits_modal/components/review_tab_container.vue';
import createFlash from '~/flash';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import {
  findCommitIndex,
  setCommitStatus,
  removeIfReadyToBeRemoved,
  removeIfPresent,
} from '../utils';

export default {
  components: {
    GlModal,
    GlTabs,
    GlTab,
    ReviewTabContainer,
    GlSearchBoxByType,
    GlSprintf,
  },
  props: {
    contextCommitsPath: {
      type: String,
      required: true,
    },
    targetBranch: {
      type: String,
      required: true,
    },
    mergeRequestIid: {
      type: Number,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'tabIndex',
      'isLoadingCommits',
      'commits',
      'commitsLoadingError',
      'isLoadingContextCommits',
      'contextCommits',
      'contextCommitsLoadingError',
      'selectedCommits',
      'searchText',
      'toRemoveCommits',
    ]),
    currentTabIndex: {
      get() {
        return this.tabIndex;
      },
      set(newTabIndex) {
        this.setTabIndex(newTabIndex);
      },
    },
    selectedCommitsCount() {
      return this.selectedCommits.filter((selectedCommit) => selectedCommit.isSelected).length;
    },
    shouldPurge() {
      return this.selectedCommitsCount !== this.selectedCommits.length;
    },
    uniqueCommits() {
      return this.selectedCommits.filter(
        (selectedCommit) =>
          selectedCommit.isSelected &&
          findCommitIndex(this.contextCommits, selectedCommit.short_id) === -1,
      );
    },
    disableSaveButton() {
      // We should have a minimum of one commit selected and that should not be in the context commits list or we should have a context commit to delete
      return (
        (this.selectedCommitsCount.length === 0 || this.uniqueCommits.length === 0) &&
        this.toRemoveCommits.length === 0
      );
    },
  },
  watch: {
    tabIndex(newTabIndex) {
      this.handleTabChange(newTabIndex);
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
    this.setBaseConfig({
      contextCommitsPath: this.contextCommitsPath,
      mergeRequestIid: this.mergeRequestIid,
      projectId: this.projectId,
    });
  },
  beforeDestroy() {
    eventHub.$off('openModal', this.openModal);
    clearTimeout(this.timeout);
    this.timeout = null;
  },
  methods: {
    ...mapActions([
      'setBaseConfig',
      'setTabIndex',
      'searchCommits',
      'setCommits',
      'createContextCommits',
      'fetchContextCommits',
      'removeContextCommits',
      'setSelectedCommits',
      'setSearchText',
      'setToRemoveCommits',
      'resetModalState',
    ]),
    focusSearch() {
      this.$refs.searchInput.focusInput();
    },
    openModal() {
      this.searchCommits();
      this.fetchContextCommits();
      this.$root.$emit(BV_SHOW_MODAL, 'add-review-item');
    },
    handleTabChange(tabIndex) {
      if (tabIndex === 0) {
        this.focusSearch();
        if (this.shouldPurge) {
          this.setSelectedCommits(
            [...this.commits, ...this.selectedCommits].filter((commit) => commit.isSelected),
          );
        }
      }
    },
    handleSearchCommits(value) {
      // We only call the service, if we have 3 characters or we don't have any characters
      if (value.length >= 3) {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
          this.searchCommits(value);
        }, 500);
      } else if (value.length === 0) {
        this.searchCommits();
      }
      this.setSearchText(value);
    },
    handleCommitRowSelect(event) {
      const index = event[0];
      const selected = event[1];
      const tempCommit = this.tabIndex === 0 ? this.commits[index] : this.selectedCommits[index];
      const commitIndex = findCommitIndex(this.commits, tempCommit.short_id);
      const tempCommits = setCommitStatus(this.commits, commitIndex, selected);
      const selectedCommitIndex = findCommitIndex(this.selectedCommits, tempCommit.short_id);
      let tempSelectedCommits = setCommitStatus(
        this.selectedCommits,
        selectedCommitIndex,
        selected,
      );

      if (selected) {
        // If user deselects a commit which is already present in previously merged commits, then user adds it again.
        // Then the state is neutral, so we remove it from the list
        this.setToRemoveCommits(
          removeIfReadyToBeRemoved(this.toRemoveCommits, tempCommit.short_id),
        );
      } else {
        // If user is present in first tab and deselects a commit, remove it directly
        if (this.tabIndex === 0) {
          tempSelectedCommits = removeIfPresent(tempSelectedCommits, tempCommit.short_id);
        }

        // If user deselects a commit which is already present in previously merged commits, we keep track of it in a list to remove
        const contextCommitsIndex = findCommitIndex(this.contextCommits, tempCommit.short_id);
        if (contextCommitsIndex !== -1) {
          this.setToRemoveCommits([...this.toRemoveCommits, tempCommit.short_id]);
        }
      }

      this.setCommits({ commits: tempCommits });
      this.setSelectedCommits([
        ...tempSelectedCommits,
        ...tempCommits.filter((commit) => commit.isSelected),
      ]);
    },
    handleCreateContextCommits() {
      if (this.uniqueCommits.length > 0 && this.toRemoveCommits.length > 0) {
        return Promise.all([
          this.createContextCommits({ commits: this.uniqueCommits }),
          this.removeContextCommits(),
        ]).then((values) => {
          if (values[0] || values[1]) {
            window.location.reload();
          }
          if (!values[0] && !values[1]) {
            createFlash({
              message: s__(
                'ContextCommits|Failed to create/remove context commits. Please try again.',
              ),
            });
          }
        });
      } else if (this.uniqueCommits.length > 0) {
        return this.createContextCommits({ commits: this.uniqueCommits, forceReload: true });
      }

      return this.removeContextCommits(true);
    },
    handleModalClose() {
      this.resetModalState();
      clearTimeout(this.timeout);
    },
    handleModalHide() {
      this.resetModalState();
      clearTimeout(this.timeout);
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    cancel-variant="light"
    size="md"
    body-class="add-review-item pt-0"
    :scrollable="true"
    :ok-title="__('Save changes')"
    modal-id="add-review-item"
    :title="__('Add or remove previously merged commits')"
    :ok-disabled="disableSaveButton"
    @shown="focusSearch"
    @ok="handleCreateContextCommits"
    @cancel="handleModalClose"
    @close="handleModalClose"
    @hide="handleModalHide"
  >
    <gl-tabs v-model="currentTabIndex" content-class="pt-0">
      <gl-tab>
        <template #title>
          <gl-sprintf :message="__(`Commits in %{codeStart}${targetBranch}%{codeEnd}`)">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </template>
        <div class="mt-2">
          <gl-search-box-by-type
            ref="searchInput"
            :placeholder="__(`Search by commit title or SHA`)"
            @input="handleSearchCommits"
          />
          <review-tab-container
            :is-loading="isLoadingCommits"
            :loading-error="commitsLoadingError"
            :loading-failed-text="__('Unable to load commits. Try again later.')"
            :commits="commits"
            :empty-list-text="__('Your search didn\'t match any commits. Try a different query.')"
            @handleCommitSelect="handleCommitRowSelect"
          />
        </div>
      </gl-tab>
      <gl-tab>
        <template #title>
          {{ __('Selected commits') }}
          <span class="badge badge-pill">{{ selectedCommitsCount }}</span>
        </template>
        <review-tab-container
          :is-loading="isLoadingContextCommits"
          :loading-error="contextCommitsLoadingError"
          :loading-failed-text="__('Unable to load commits. Try again later.')"
          :commits="selectedCommits"
          :empty-list-text="
            __(
              'Commits you select appear here. Go to the first tab and select commits to add to this merge request.',
            )
          "
          @handleCommitSelect="handleCommitRowSelect"
        />
      </gl-tab>
    </gl-tabs>
  </gl-modal>
</template>
