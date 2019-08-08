<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { polyfillSticky } from '~/lib/utils/sticky';
import Icon from '~/vue_shared/components/icon.vue';
import CompareVersionsDropdown from './compare_versions_dropdown.vue';
import SettingsDropdown from './settings_dropdown.vue';
import DiffStats from './diff_stats.vue';
import { CENTERED_LIMITED_CONTAINER_CLASSES } from '../constants';

export default {
  components: {
    CompareVersionsDropdown,
    Icon,
    GlLink,
    GlButton,
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
    mergeRequestDiff: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    targetBranch: {
      type: Object,
      required: false,
      default: null,
    },
    isLimitedContainer: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters('diffs', ['hasCollapsedFile', 'diffFilesLength']),
    ...mapState('diffs', [
      'commit',
      'showTreeList',
      'startVersion',
      'latestVersionPath',
      'addedLines',
      'removedLines',
    ]),
    comparableDiffs() {
      return this.mergeRequestDiffs.slice(1);
    },
    showDropdowns() {
      return !this.commit && this.mergeRequestDiffs.length;
    },
    fileTreeIcon() {
      return this.showTreeList ? 'collapse-left' : 'expand-left';
    },
    toggleFileBrowserTitle() {
      return this.showTreeList ? __('Hide file browser') : __('Show file browser');
    },
    baseVersionPath() {
      return this.mergeRequestDiff.base_version_path;
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
  <div class="mr-version-controls border-top border-bottom">
    <div
      class="mr-version-menus-container content-block"
      :class="{
        [CENTERED_LIMITED_CONTAINER_CLASSES]: isLimitedContainer,
      }"
    >
      <button
        v-gl-tooltip.hover
        type="button"
        class="btn btn-default append-right-8 js-toggle-tree-list"
        :class="{
          active: showTreeList,
        }"
        :title="toggleFileBrowserTitle"
        @click="toggleShowTreeList"
      >
        <icon :name="fileTreeIcon" />
      </button>
      <div v-if="showDropdowns" class="d-flex align-items-center compare-versions-container">
        Changes between
        <compare-versions-dropdown
          :other-versions="mergeRequestDiffs"
          :merge-request-version="mergeRequestDiff"
          :show-commit-count="true"
          class="mr-version-dropdown"
        />
        and
        <compare-versions-dropdown
          :other-versions="comparableDiffs"
          :base-version-path="baseVersionPath"
          :start-version="startVersion"
          :target-branch="targetBranch"
          class="mr-version-compare-dropdown"
        />
      </div>
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
        <gl-button
          v-if="commit || startVersion"
          :href="latestVersionPath"
          class="append-right-8 js-latest-version"
        >
          {{ __('Show latest version') }}
        </gl-button>
        <gl-button v-show="hasCollapsedFile" class="append-right-8" @click="expandAllFiles">
          {{ __('Expand all') }}
        </gl-button>
        <settings-dropdown />
      </div>
    </div>
  </div>
</template>
