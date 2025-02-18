<script>
import { GlIcon, GlLink, GlSkeletonLoader, GlLoadingIcon, GlSprintf, GlButton } from '@gitlab/ui';
import { s__, sprintf, n__ } from '~/locale';
import { createAlert, VARIANT_INFO } from '~/alert';
import syncForkMutation from '~/repository/mutations/sync_fork.mutation.graphql';
import eventHub from '../event_hub';
import {
  POLLING_INTERVAL_DEFAULT,
  POLLING_INTERVAL_BACKOFF,
  FIVE_MINUTES_IN_MS,
  FORK_UPDATED_EVENT,
} from '../constants';
import forkDetailsQuery from '../queries/fork_details.query.graphql';
import ConflictsModal from './fork_sync_conflicts_modal.vue';

export const i18n = {
  forkedFrom: s__('ForkedFromProjectPath|Forked from'),
  inaccessibleProject: s__('ForkedFromProjectPath|Forked from an inaccessible project.'),
  upToDate: s__('ForksDivergence|Up to date with the upstream repository.'),
  unknown: s__('ForksDivergence|This fork has diverged from the upstream repository.'),
  behind: s__('ForksDivergence|%{behindLinkStart}%{behind} %{commit_word} behind%{behindLinkEnd}'),
  ahead: s__('ForksDivergence|%{aheadLinkStart}%{ahead} %{commit_word} ahead%{aheadLinkEnd} of'),
  behindAhead: s__('ForksDivergence|%{messages} the upstream repository.'),
  limitedVisibility: s__('ForksDivergence|Source project has a limited visibility.'),
  error: s__('ForksDivergence|Failed to fetch fork details. Try again later.'),
  updateFork: s__('ForksDivergence|Update fork'),
  createMergeRequest: s__('ForksDivergence|Create merge request'),
  viewMergeRequest: s__('ForksDivergence|View merge request'),
  successMessage: s__(
    'ForksDivergence|Successfully fetched and merged from the upstream repository.',
  ),
};

export default {
  i18n,
  components: {
    GlIcon,
    GlLink,
    GlButton,
    GlSprintf,
    GlSkeletonLoader,
    ConflictsModal,
    GlLoadingIcon,
  },
  apollo: {
    project: {
      query: forkDetailsQuery,
      notifyOnNetworkStatusChange: true,
      variables() {
        return this.forkDetailsQueryVariables;
      },
      skip() {
        return !this.sourceName;
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.error,
          captureError: true,
          error,
        });
      },
      result({ loading }) {
        if (!loading && this.isSyncing) {
          this.increasePollInterval();
        }
        if (this.isForkUpdated) {
          createAlert({
            message: this.$options.i18n.successMessage,
            variant: VARIANT_INFO,
          });
          eventHub.$emit(FORK_UPDATED_EVENT);
        }
      },
      pollInterval() {
        return this.pollInterval;
      },
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    selectedBranch: {
      type: String,
      required: true,
    },
    sourceDefaultBranch: {
      type: String,
      required: false,
      default: '',
    },
    sourceName: {
      type: String,
      required: false,
      default: '',
    },
    sourcePath: {
      type: String,
      required: false,
      default: '',
    },
    canSyncBranch: {
      type: Boolean,
      required: false,
      default: false,
    },
    aheadComparePath: {
      type: String,
      required: false,
      default: '',
    },
    behindComparePath: {
      type: String,
      required: false,
      default: '',
    },
    createMrPath: {
      type: String,
      required: false,
      default: '',
    },
    viewMrPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      project: {},
      currentPollInterval: null,
    };
  },
  computed: {
    forkDetailsQueryVariables() {
      return {
        projectPath: this.projectPath,
        ref: this.selectedBranch,
      };
    },
    pollInterval() {
      return this.isSyncing ? this.currentPollInterval : 0;
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
    forkDetails() {
      return this.project?.forkDetails;
    },
    hasConflicts() {
      return this.forkDetails?.hasConflicts;
    },
    isSyncing() {
      return this.forkDetails?.isSyncing;
    },
    isForkUpdated() {
      return this.isUpToDate && this.currentPollInterval;
    },
    ahead() {
      return this.project?.forkDetails?.ahead;
    },
    behind() {
      return this.project?.forkDetails?.behind;
    },
    behindText() {
      return sprintf(this.$options.i18n.behind, {
        behind: this.behind,
        commit_word: n__('commit', 'commits', this.behind),
      });
    },
    aheadText() {
      return sprintf(this.$options.i18n.ahead, {
        ahead: this.ahead,
        commit_word: n__('commit', 'commits', this.ahead),
      });
    },
    isUnknownDivergence() {
      return this.sourceName && this.ahead === null && this.behind === null;
    },
    isUpToDate() {
      return this.ahead === 0 && this.behind === 0;
    },
    behindAheadMessage() {
      const messages = [];
      if (this.behind > 0) {
        messages.push(this.behindText);
      }
      if (this.ahead > 0) {
        messages.push(this.aheadText);
      }
      return messages.join(', ');
    },
    hasBehindAheadMessage() {
      return this.behindAheadMessage.length > 0;
    },
    hasUpdateButton() {
      return (
        this.canSyncBranch &&
        ((this.sourceName && this.forkDetails && this.behind) || this.isUnknownDivergence)
      );
    },
    hasCreateMrButton() {
      return this.ahead && this.createMrPath;
    },
    hasViewMrButton() {
      return this.viewMrPath;
    },
    forkDivergenceMessage() {
      if (!this.forkDetails) {
        return this.$options.i18n.limitedVisibility;
      }
      if (this.isUnknownDivergence) {
        return this.$options.i18n.unknown;
      }
      if (this.hasBehindAheadMessage) {
        return sprintf(
          this.$options.i18n.behindAhead,
          {
            messages: this.behindAheadMessage,
          },
          false,
        );
      }
      return this.$options.i18n.upToDate;
    },
  },
  watch: {
    hasConflicts(newVal) {
      if (newVal && this.currentPollInterval) {
        this.showConflictsModal();
      }
    },
  },
  methods: {
    async syncForkWithPolling() {
      await this.$apollo.mutate({
        mutation: syncForkMutation,
        variables: {
          projectPath: this.projectPath,
          targetBranch: this.selectedBranch,
        },
        error(error) {
          createAlert({
            message: error.message,
            captureError: true,
            error,
          });
        },
        update: (store, { data: { projectSyncFork } }) => {
          const { details } = projectSyncFork;

          store.writeQuery({
            query: forkDetailsQuery,
            variables: this.forkDetailsQueryVariables,
            data: {
              project: {
                id: this.project.id,
                forkDetails: details,
              },
            },
          });
        },
      });
    },
    showConflictsModal() {
      this.$refs.modal.show();
    },
    startSyncing() {
      this.syncForkWithPolling();
    },
    checkIfSyncIsPossible() {
      if (this.hasConflicts) {
        this.showConflictsModal();
      } else {
        this.startSyncing();
      }
    },
    increasePollInterval() {
      const backoff = POLLING_INTERVAL_BACKOFF;
      const interval = this.currentPollInterval;
      const newInterval = Math.min(interval * backoff, FIVE_MINUTES_IN_MS);
      this.currentPollInterval = this.currentPollInterval ? newInterval : POLLING_INTERVAL_DEFAULT;
    },
  },
};
</script>

<template>
  <div class="info-well gl-mt-5 gl-flex-col sm:gl-flex">
    <div class="well-segment gl-flex gl-w-full gl-p-5">
      <gl-icon name="fork" :size="16" class="gl-m-4 gl-block gl-text-center" />
      <div class="gl-flex gl-grow gl-items-center gl-justify-between">
        <div v-if="sourceName">
          {{ $options.i18n.forkedFrom }}
          <gl-link data-testid="forked-from-link" :href="sourcePath">{{ sourceName }}</gl-link>
          <gl-skeleton-loader v-if="isLoading" :lines="1" />
          <div v-else class="gl-text-subtle" data-testid="divergence-message">
            <gl-sprintf :message="forkDivergenceMessage">
              <template #aheadLink="{ content }">
                <gl-link :href="aheadComparePath">{{ content }}</gl-link>
              </template>
              <template #behindLink="{ content }">
                <gl-link :href="behindComparePath">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </div>
        </div>
        <div v-else data-testid="inaccessible-project" class="gl-flex gl-items-center">
          {{ $options.i18n.inaccessibleProject }}
        </div>
        <div class="gl-hidden sm:gl-flex">
          <gl-button
            v-if="hasCreateMrButton"
            class="gl-ml-4"
            :href="createMrPath"
            data-testid="create-mr-button"
          >
            <span>{{ $options.i18n.createMergeRequest }}</span>
          </gl-button>
          <gl-button
            v-if="hasViewMrButton"
            class="gl-ml-4"
            :href="viewMrPath"
            data-testid="view-mr-button"
          >
            <span>{{ $options.i18n.viewMergeRequest }}</span>
          </gl-button>
          <gl-button
            v-if="hasUpdateButton"
            class="gl-ml-4"
            :disabled="forkDetails.isSyncing"
            data-testid="update-fork-button"
            @click="checkIfSyncIsPossible"
          >
            <gl-loading-icon v-if="forkDetails.isSyncing" class="gl-inline" size="sm" />
            <span>{{ $options.i18n.updateFork }}</span>
          </gl-button>
        </div>
        <conflicts-modal
          ref="modal"
          :selected-branch="selectedBranch"
          :source-name="sourceName"
          :source-path="sourcePath"
          :source-default-branch="sourceDefaultBranch"
        />
      </div>
    </div>
  </div>
</template>
