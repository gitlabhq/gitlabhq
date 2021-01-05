<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlLink, GlButton, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { polyfillSticky } from '~/lib/utils/sticky';
import CompareDropdownLayout from './compare_dropdown_layout.vue';
import SettingsDropdown from './settings_dropdown.vue';
import DiffStats from './diff_stats.vue';
import { CENTERED_LIMITED_CONTAINER_CLASSES, EVT_EXPAND_ALL_FILES } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    CompareDropdownLayout,
    GlLink,
    GlButton,
    GlSprintf,
    SettingsDropdown,
    DiffStats,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isLimitedContainer: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    toggleFileBrowserTitle() {
      return this.showTreeList ? __('Hide file browser') : __('Show file browser');
    },
    hasChanges() {
      return this.diffFiles.length > 0;
    },
    hasSourceVersions() {
      return this.diffCompareDropdownSourceVersions.length > 0;
    },
  },
  created() {
    this.CENTERED_LIMITED_CONTAINER_CLASSES = CENTERED_LIMITED_CONTAINER_CLASSES;
  },
  mounted() {
    polyfillSticky(this.$el);
  },
  methods: {
    ...mapActions('diffs', ['setInlineDiffViewType', 'setParallelDiffViewType', 'setShowTreeList']),
    expandAllFiles() {
      eventHub.$emit(EVT_EXPAND_ALL_FILES);
    },
  },
};
</script>

<template>
  <div class="mr-version-controls border-top">
    <div
      class="mr-version-menus-container content-block"
      :class="{
        [CENTERED_LIMITED_CONTAINER_CLASSES]: isLimitedContainer,
      }"
    >
      <gl-button
        v-if="hasChanges"
        v-gl-tooltip.hover
        variant="default"
        icon="file-tree"
        class="gl-mr-3 js-toggle-tree-list"
        :title="toggleFileBrowserTitle"
        :selected="showTreeList"
        @click="setShowTreeList({ showTreeList: !showTreeList })"
      />
      <div v-if="commit">
        {{ __('Viewing commit') }}
        <gl-link :href="commit.commit_url" class="monospace">{{ commit.short_id }}</gl-link>
      </div>
      <gl-sprintf
        v-else-if="hasSourceVersions"
        class="d-flex align-items-center compare-versions-container"
        :message="s__('MergeRequest|Compare %{target} and %{source}')"
      >
        <template #target>
          <compare-dropdown-layout
            :versions="diffCompareDropdownTargetVersions"
            class="mr-version-compare-dropdown"
            data-qa-selector="target_version_dropdown"
          />
        </template>
        <template #source>
          <compare-dropdown-layout
            :versions="diffCompareDropdownSourceVersions"
            class="mr-version-dropdown"
          />
        </template>
      </gl-sprintf>
      <div v-if="hasChanges" class="inline-parallel-buttons d-none d-md-flex ml-auto">
        <diff-stats
          :diff-files-count-text="diffFilesCountText"
          :added-lines="addedLines"
          :removed-lines="removedLines"
        />
        <gl-button
          v-if="commit || startVersion"
          :href="latestVersionPath"
          variant="default"
          class="gl-mr-3 js-latest-version"
        >
          {{ __('Show latest version') }}
        </gl-button>
        <gl-button
          v-show="whichCollapsedTypes.any"
          variant="default"
          class="gl-mr-3"
          @click="expandAllFiles"
        >
          {{ __('Expand all') }}
        </gl-button>
        <settings-dropdown />
      </div>
    </div>
  </div>
</template>
