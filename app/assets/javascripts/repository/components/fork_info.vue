<script>
import { GlIcon, GlLink, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { s__, sprintf, n__ } from '~/locale';
import { createAlert } from '~/flash';
import forkDetailsQuery from '../queries/fork_details.query.graphql';

export const i18n = {
  forkedFrom: s__('ForkedFromProjectPath|Forked from'),
  inaccessibleProject: s__('ForkedFromProjectPath|Forked from an inaccessible project.'),
  upToDate: s__('ForksDivergence|Up to date with the upstream repository.'),
  unknown: s__('ForksDivergence|This fork has diverged from the upstream repository.'),
  behind: s__('ForksDivergence|%{behindLinkStart}%{behind} %{commit_word} behind%{behindLinkEnd}'),
  ahead: s__('ForksDivergence|%{aheadLinkStart}%{ahead} %{commit_word} ahead%{aheadLinkEnd} of'),
  behindAhead: s__('ForksDivergence|%{messages} the upstream repository.'),
  error: s__('ForksDivergence|Failed to fetch fork details. Try again later.'),
};

export default {
  i18n,
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
  },
  apollo: {
    project: {
      query: forkDetailsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          ref: this.selectedBranch,
        };
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
  },
  data() {
    return {
      project: {
        forkDetails: {
          ahead: null,
          behind: null,
        },
      },
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.project.loading;
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
      return (!this.ahead && this.ahead !== 0) || (!this.behind && this.behind !== 0);
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
    forkDivergenceMessage() {
      if (this.isUnknownDivergence) {
        return this.$options.i18n.unknown;
      }
      if (this.hasBehindAheadMessage) {
        return sprintf(this.$options.i18n.behindAhead, {
          messages: this.behindAheadMessage,
        });
      }
      return this.$options.i18n.upToDate;
    },
  },
};
</script>

<template>
  <div class="info-well gl-sm-display-flex gl-flex-direction-column">
    <div class="well-segment gl-p-5 gl-w-full gl-display-flex">
      <gl-icon name="fork" :size="16" class="gl-display-block gl-m-4 gl-text-center" />
      <div v-if="sourceName">
        {{ $options.i18n.forkedFrom }}
        <gl-link data-qa-selector="forked_from_link" :href="sourcePath">{{ sourceName }}</gl-link>
        <gl-skeleton-loader v-if="isLoading" :lines="1" />
        <div v-else class="gl-text-secondary" data-testid="divergence-message">
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
      <div v-else data-testid="inaccessible-project" class="gl-align-items-center gl-display-flex">
        {{ $options.i18n.inaccessibleProject }}
      </div>
    </div>
  </div>
</template>
