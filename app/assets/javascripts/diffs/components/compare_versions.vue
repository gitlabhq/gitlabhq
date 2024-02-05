<script>
import { GlTooltipDirective, GlIcon, GlLink, GlButtonGroup, GlButton, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import { setUrlParams } from '~/lib/utils/url_utility';
import {
  keysFor,
  MR_COMMITS_NEXT_COMMIT,
  MR_COMMITS_PREVIOUS_COMMIT,
  MR_TOGGLE_FILE_BROWSER,
} from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { EVT_EXPAND_ALL_FILES } from '../constants';
import eventHub from '../event_hub';
import CompareDropdownLayout from './compare_dropdown_layout.vue';
import DiffStats from './diff_stats.vue';
import SettingsDropdown from './settings_dropdown.vue';

export default {
  components: {
    CompareDropdownLayout,
    GlIcon,
    GlLink,
    GlButtonGroup,
    GlButton,
    GlSprintf,
    SettingsDropdown,
    DiffStats,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    diffFilesCountText: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapGetters('diffs', [
      'whichCollapsedTypes',
      'diffCompareDropdownTargetVersions',
      'diffCompareDropdownSourceVersions',
    ]),
    ...mapState('diffs', [
      'diffFiles',
      'commit',
      'showTreeList',
      'startVersion',
      'latestVersionPath',
      'addedLines',
      'removedLines',
    ]),
    toggleFileBrowserShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(MR_TOGGLE_FILE_BROWSER)[0];
    },
    toggleFileBrowserTitle() {
      return this.showTreeList ? __('Hide file browser') : __('Show file browser');
    },
    toggleFileBrowserTooltip() {
      const description = this.toggleFileBrowserTitle;
      const key = this.toggleFileBrowserShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    hasChanges() {
      return this.diffFiles.length > 0;
    },
    hasSourceVersions() {
      return this.diffCompareDropdownSourceVersions.length > 0;
    },
    nextCommitUrl() {
      return this.commit.next_commit_id
        ? setUrlParams({ commit_id: this.commit.next_commit_id })
        : '';
    },
    nextCommitShortcutKey() {
      return shouldDisableShortcuts() || !this.commit.next_commit_id
        ? null
        : keysFor(MR_COMMITS_NEXT_COMMIT)[0];
    },
    nextCommitTitle() {
      return !this.commit.next_commit_id
        ? __("You're at the last commit")
        : MR_COMMITS_NEXT_COMMIT.description;
    },
    nextCommitTooltip() {
      const description = this.nextCommitTitle;
      const key = this.nextCommitShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    previousCommitUrl() {
      return this.commit.prev_commit_id
        ? setUrlParams({ commit_id: this.commit.prev_commit_id })
        : '';
    },
    previousCommitShortcutKey() {
      return shouldDisableShortcuts() || !this.commit.prev_commit_id
        ? null
        : keysFor(MR_COMMITS_PREVIOUS_COMMIT)[0];
    },
    previousCommitTitle() {
      return !this.commit.prev_commit_id
        ? __("You're at the first commit")
        : MR_COMMITS_PREVIOUS_COMMIT.description;
    },
    previousCommitTooltip() {
      const description = this.previousCommitTitle;
      const key = this.previousCommitShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
    hasNeighborCommits() {
      return this.commit && (this.commit.next_commit_id || this.commit.prev_commit_id);
    },
  },
  methods: {
    ...mapActions('diffs', ['setInlineDiffViewType', 'setParallelDiffViewType', 'setShowTreeList']),
    expandAllFiles() {
      eventHub.$emit(EVT_EXPAND_ALL_FILES);
    },
    ...mapActions('diffs', ['moveToNeighboringCommit']),
  },
};
</script>

<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container gl-px-5 gl-pt-3 gl-pb-2">
      <gl-button
        v-if="hasChanges"
        v-gl-tooltip.html="toggleFileBrowserTooltip"
        variant="default"
        icon="file-tree"
        class="gl-mr-3 js-toggle-tree-list btn-icon"
        data-testid="file-tree-button"
        :aria-label="toggleFileBrowserTitle"
        :aria-keyshortcuts="toggleFileBrowserShortcutKey"
        :selected="showTreeList"
        @click="setShowTreeList({ showTreeList: !showTreeList })"
      />
      <div v-if="commit">
        {{ __('Viewing commit') }}
        <gl-link :href="commit.commit_url" class="monospace">{{ commit.short_id }}</gl-link>
      </div>
      <div v-if="hasNeighborCommits" class="commit-nav-buttons">
        <gl-button-group>
          <gl-button
            v-gl-tooltip.html="previousCommitTooltip"
            :aria-label="previousCommitTitle"
            :aria-keyshortcuts="previousCommitShortcutKey"
            :href="previousCommitUrl"
            :disabled="!commit.prev_commit_id"
            @click.prevent="moveToNeighboringCommit({ direction: 'previous' })"
          >
            <span
              v-if="!commit.prev_commit_id"
              v-gl-tooltip
              class="gl-h-full gl-w-full position-absolute position-top-0 position-left-0"
              :title="__('You\'re at the first commit')"
            ></span>
            <gl-icon name="chevron-left" />
            {{ __('Prev') }}
          </gl-button>
          <gl-button
            v-gl-tooltip.html="nextCommitTooltip"
            :aria-label="nextCommitTitle"
            :aria-keyshortcuts="nextCommitShortcutKey"
            :href="nextCommitUrl"
            :disabled="!commit.next_commit_id"
            @click.prevent="moveToNeighboringCommit({ direction: 'next' })"
          >
            <span
              v-if="!commit.next_commit_id"
              v-gl-tooltip
              class="gl-h-full gl-w-full position-absolute position-top-0 position-left-0"
              :title="__('You\'re at the last commit')"
            ></span>
            {{ __('Next') }}
            <gl-icon name="chevron-right" />
          </gl-button>
        </gl-button-group>
      </div>
      <gl-sprintf
        v-else-if="!commit && hasSourceVersions"
        class="d-flex gl-align-items-center compare-versions-container"
        :message="s__('MergeRequest|Compare %{target} and %{source}')"
      >
        <template #target>
          <compare-dropdown-layout
            :versions="diffCompareDropdownTargetVersions"
            class="mr-version-compare-dropdown"
            data-testid="target-version-dropdown"
          />
        </template>
        <template #source>
          <compare-dropdown-layout
            :versions="diffCompareDropdownSourceVersions"
            class="mr-version-dropdown"
          />
        </template>
      </gl-sprintf>
      <gl-button
        v-if="commit || startVersion"
        :href="latestVersionPath"
        variant="default"
        class="js-latest-version"
        :class="{ 'gl-ml-3': commit && !hasNeighborCommits }"
      >
        {{ __('Show latest version') }}
      </gl-button>
      <div v-if="hasChanges" class="inline-parallel-buttons d-none gl-md-display-flex! ml-auto">
        <diff-stats
          :diff-files-count-text="diffFilesCountText"
          :added-lines="addedLines"
          :removed-lines="removedLines"
        />
        <gl-button
          v-show="whichCollapsedTypes.any"
          variant="default"
          class="gl-mr-3"
          @click="expandAllFiles"
        >
          {{ __('Expand all files') }}
        </gl-button>
        <settings-dropdown />
      </div>
    </div>
  </div>
</template>
