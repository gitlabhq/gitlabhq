<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlLink, GlDeprecatedButton, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { polyfillSticky } from '~/lib/utils/sticky';
import Icon from '~/vue_shared/components/icon.vue';
import CompareDropdownLayout from './compare_dropdown_layout.vue';
import SettingsDropdown from './settings_dropdown.vue';
import DiffStats from './diff_stats.vue';
import { CENTERED_LIMITED_CONTAINER_CLASSES } from '../constants';

export default {
  components: {
    CompareDropdownLayout,
    Icon,
    GlLink,
    GlDeprecatedButton,
    GlSprintf,
    SettingsDropdown,
    DiffStats,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    mergeRequestDiffs: {
      type: Array,
      required: true,
    },
    isLimitedContainer: {
      type: Boolean,
      required: false,
      default: false,
    },
    diffFilesLength: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', [
      'hasCollapsedFile',
      'diffCompareDropdownTargetVersions',
      'diffCompareDropdownSourceVersions',
    ]),
    ...mapState('diffs', [
      'commit',
      'showTreeList',
      'startVersion',
      'latestVersionPath',
      'addedLines',
      'removedLines',
    ]),
    showDropdowns() {
      return !this.commit && this.mergeRequestDiffs.length;
    },
    toggleFileBrowserTitle() {
      return this.showTreeList ? __('Hide file browser') : __('Show file browser');
    },
  },
  created() {
    this.CENTERED_LIMITED_CONTAINER_CLASSES = CENTERED_LIMITED_CONTAINER_CLASSES;
  },
  mounted() {
    polyfillSticky(this.$el);
  },
  methods: {
    ...mapActions('diffs', [
      'setInlineDiffViewType',
      'setParallelDiffViewType',
      'expandAllFiles',
      'toggleShowTreeList',
    ]),
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
      <button
        v-gl-tooltip.hover
        type="button"
        class="btn btn-default gl-mr-3 js-toggle-tree-list"
        :class="{
          active: showTreeList,
        }"
        :title="toggleFileBrowserTitle"
        @click="toggleShowTreeList"
      >
        <icon name="file-tree" />
      </button>
      <gl-sprintf
        v-if="showDropdowns"
        class="d-flex align-items-center compare-versions-container"
        :message="s__('MergeRequest|Compare %{target} and %{source}')"
      >
        <template #target>
          <compare-dropdown-layout
            :versions="diffCompareDropdownTargetVersions"
            class="mr-version-compare-dropdown"
          />
        </template>
        <template #source>
          <compare-dropdown-layout
            :versions="diffCompareDropdownSourceVersions"
            class="mr-version-dropdown"
          />
        </template>
      </gl-sprintf>
      <div v-else-if="commit">
        {{ __('Viewing commit') }}
        <gl-link :href="commit.commit_url" class="monospace">{{ commit.short_id }}</gl-link>
      </div>
      <div class="inline-parallel-buttons d-none d-md-flex ml-auto">
        <diff-stats
          :diff-files-length="diffFilesLength"
          :added-lines="addedLines"
          :removed-lines="removedLines"
        />
        <gl-deprecated-button
          v-if="commit || startVersion"
          :href="latestVersionPath"
          class="gl-mr-3 js-latest-version"
        >
          {{ __('Show latest version') }}
        </gl-deprecated-button>
        <gl-deprecated-button v-show="hasCollapsedFile" class="gl-mr-3" @click="expandAllFiles">
          {{ __('Expand all') }}
        </gl-deprecated-button>
        <settings-dropdown />
      </div>
    </div>
  </div>
</template>
