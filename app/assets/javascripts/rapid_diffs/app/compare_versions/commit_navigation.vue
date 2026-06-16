<script>
import { GlLink, GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { removeParams, setUrlParams } from '~/lib/utils/url_utility';

export default {
  name: 'CommitNavigation',
  components: {
    GlLink,
    GlButton,
    GlButtonGroup,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      latestVersionUrl: removeParams(['commit_id']),
    };
  },
  computed: {
    hasNeighborCommits() {
      return Boolean(this.commit.next_commit_id || this.commit.prev_commit_id);
    },
    previousCommitUrl() {
      return this.commit.prev_commit_id
        ? setUrlParams({ commit_id: this.commit.prev_commit_id })
        : '';
    },
    nextCommitUrl() {
      return this.commit.next_commit_id
        ? setUrlParams({ commit_id: this.commit.next_commit_id })
        : '';
    },
    previousCommitTitle() {
      let title = __('Previous commit');

      if (!this.commit.prev_commit_id) {
        title = __("You're at the first commit");
      }

      return title;
    },
    nextCommitTitle() {
      let title = __('Next commit');

      if (!this.commit.next_commit_id) {
        title = __("You're at the last commit");
      }

      return title;
    },
  },
  i18n: {
    viewingCommit: __('Viewing commit'),
    showLatestVersion: __('Show latest version'),
    previous: __('Previous'),
    next: __('Next'),
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-3">
    <div>
      {{ $options.i18n.viewingCommit }}
      <gl-link :href="commit.commit_url" class="gl-font-monospace">{{ commit.short_id }}</gl-link>
    </div>
    <gl-button-group v-if="hasNeighborCommits" data-testid="commit-nav-buttons">
      <gl-button
        v-gl-tooltip="previousCommitTitle"
        :aria-label="previousCommitTitle"
        :href="previousCommitUrl"
        :disabled="!commit.prev_commit_id"
        size="small"
        data-testid="prev-commit-button"
      >
        <gl-icon name="chevron-left" />
        {{ $options.i18n.previous }}
      </gl-button>
      <gl-button
        v-gl-tooltip="nextCommitTitle"
        :aria-label="nextCommitTitle"
        :href="nextCommitUrl"
        :disabled="!commit.next_commit_id"
        size="small"
        data-testid="next-commit-button"
      >
        {{ $options.i18n.next }}
        <gl-icon name="chevron-right" />
      </gl-button>
    </gl-button-group>
    <gl-button
      :href="latestVersionUrl"
      size="small"
      class="gl-shrink-0"
      data-testid="show-latest-version-button"
    >
      {{ $options.i18n.showLatestVersion }}
    </gl-button>
  </div>
</template>
