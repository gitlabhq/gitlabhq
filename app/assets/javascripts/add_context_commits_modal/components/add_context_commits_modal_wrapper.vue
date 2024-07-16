<script>
import { GlModal, GlTabs, GlTab, GlSprintf, GlBadge, GlFilteredSearch } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import ReviewTabContainer from '~/add_context_commits_modal/components/review_tab_container.vue';
import { createAlert } from '~/alert';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import {
  OPERATORS_IS,
  TOKEN_TYPE_AUTHOR,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import eventHub from '../event_hub';
import {
  findCommitIndex,
  setCommitStatus,
  removeIfReadyToBeRemoved,
  removeIfPresent,
} from '../utils';
import Token from './token.vue';
import DateOption from './date_option.vue';

export default {
  components: {
    GlModal,
    GlTabs,
    GlTab,
    ReviewTabContainer,
    GlSprintf,
    GlBadge,
    GlFilteredSearch,
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
  data() {
    return {
      availableTokens: [
        {
          icon: 'pencil',
          title: __('Author'),
          type: TOKEN_TYPE_AUTHOR,
          operators: OPERATORS_IS,
          token: UserToken,
          defaultAuthors: [],
          unique: true,
          fetchAuthors: this.fetchAuthors,
          initialAuthors: [],
        },
        {
          formattedKey: __('Committed-before'),
          key: 'committed-before',
          type: 'committed-before-date',
          param: '',
          symbol: '',
          icon: 'clock',
          tag: 'committed_before',
          title: __('Committed-before'),
          operators: OPERATORS_IS,
          token: Token,
          unique: true,
          optionComponent: DateOption,
        },
        {
          formattedKey: __('Committed-after'),
          key: 'committed-after',
          type: 'committed-after-date',
          param: '',
          symbol: '',
          icon: 'clock',
          tag: 'committed_after',
          title: __('Committed-after'),
          operators: OPERATORS_IS,
          token: Token,
          unique: true,
          optionComponent: DateOption,
        },
      ],
    };
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
      'fetchAuthors',
    ]),
    openModal() {
      this.searchCommits();
      this.fetchContextCommits();
      this.$root.$emit(BV_SHOW_MODAL, 'add-review-item');
    },
    handleTabChange(tabIndex) {
      if (tabIndex === 0) {
        if (this.shouldPurge) {
          this.setSelectedCommits(
            [...this.commits, ...this.selectedCommits].filter((commit) => commit.isSelected),
          );
        }
      }
    },
    blurSearchInput() {
      const searchInputEl = this.$refs.filteredSearchInput.$el.querySelector(
        '.gl-filtered-search-token-segment-input',
      );
      if (searchInputEl) {
        searchInputEl.blur();
      }
    },
    handleSearchCommits(value = []) {
      const searchValues = value.reduce((acc, searchFilter) => {
        const isEqualSearch = searchFilter?.value?.operator === '=';

        if (!isEqualSearch && typeof searchFilter === 'object') return acc;

        if (typeof searchFilter === 'string' && searchFilter.length >= 3) {
          acc.searchText = searchFilter;
        } else if (searchFilter?.type === 'author' && searchFilter?.value?.data?.length >= 3) {
          acc.author = searchFilter?.value?.data;
        } else if (searchFilter?.type === 'committed-before-date') {
          acc.committed_before = searchFilter?.value?.data;
        } else if (searchFilter?.type === 'committed-after-date') {
          acc.committed_after = searchFilter?.value?.data;
        }

        return acc;
      }, {});

      this.searchCommits(searchValues);
      this.blurSearchInput();
      this.setSearchText(searchValues.searchText);
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
            createAlert({
              message: s__(
                'ContextCommits|Failed to create/remove context commits. Please try again.',
              ),
            });
          }
        });
      }
      if (this.uniqueCommits.length > 0) {
        return this.createContextCommits({ commits: this.uniqueCommits, forceReload: true });
      }

      return this.removeContextCommits(true);
    },
    handleModalClose() {
      this.resetModalState();
    },
    handleModalHide() {
      this.resetModalState();
    },
    shouldShowInputDateFormat(value) {
      return ['Committed-before', 'Committed-after'].indexOf(value) !== -1;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    cancel-variant="light"
    size="md"
    no-focus-on-show
    modal-class="add-review-item-modal"
    body-class="add-review-item pt-0"
    :scrollable="true"
    :ok-title="__('Save changes')"
    modal-id="add-review-item"
    :title="__('Add or remove previously merged commits')"
    :ok-disabled="disableSaveButton"
    @ok="handleCreateContextCommits"
    @cancel="handleModalClose"
    @close="handleModalClose"
    @hide="handleModalHide"
  >
    <gl-tabs v-model="currentTabIndex" content-class="pt-0">
      <gl-tab>
        <template #title>
          <gl-sprintf :message="__('Commits in %{branchName}')">
            <template #branchName>
              <code class="gl-ml-2">{{ targetBranch }}</code>
            </template>
          </gl-sprintf>
        </template>
        <div class="gl-mt-3">
          <gl-filtered-search
            ref="filteredSearchInput"
            class="flex-grow-1"
            :placeholder="__(`Search or filter commits`)"
            :available-tokens="availableTokens"
            @clear="handleSearchCommits"
            @submit="handleSearchCommits"
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
          <gl-badge class="gl-ml-2">{{ selectedCommitsCount }}</gl-badge>
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
