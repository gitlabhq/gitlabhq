<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Tooltip from '@gitlab/ui/dist/directives/tooltip';
import { __ } from '~/locale';
import { getParameterValues, mergeUrlParams } from '~/lib/utils/url_utility';
import Icon from '~/vue_shared/components/icon.vue';
import CompareVersionsDropdown from './compare_versions_dropdown.vue';

export default {
  components: {
    CompareVersionsDropdown,
    Icon,
  },
  directives: {
    Tooltip,
  },
  props: {
    mergeRequestDiffs: {
      type: Array,
      required: true,
    },
    mergeRequestDiff: {
      type: Object,
      required: true,
    },
    startVersion: {
      type: Object,
      required: false,
      default: null,
    },
    targetBranch: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState('diffs', ['commit', 'showTreeList']),
    ...mapGetters('diffs', ['isInlineView', 'isParallelView', 'hasCollapsedFile']),
    comparableDiffs() {
      return this.mergeRequestDiffs.slice(1);
    },
    toggleWhitespaceText() {
      if (this.isWhitespaceVisible()) {
        return __('Hide whitespace changes');
      }
      return __('Show whitespace changes');
    },
    toggleWhitespacePath() {
      if (this.isWhitespaceVisible()) {
        return mergeUrlParams({ w: 1 }, window.location.href);
      }

      return mergeUrlParams({ w: 0 }, window.location.href);
    },
    showDropdowns() {
      return !this.commit && this.mergeRequestDiffs.length;
    },
  },
  methods: {
    ...mapActions('diffs', [
      'setInlineDiffViewType',
      'setParallelDiffViewType',
      'expandAllFiles',
      'toggleShowTreeList',
    ]),
    isWhitespaceVisible() {
      return getParameterValues('w')[0] !== '1';
    },
  },
};
</script>

<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container content-block">
      <button
        v-tooltip.hover
        type="button"
        class="btn btn-default append-right-8 js-toggle-tree-list"
        :class="{
          active: showTreeList,
        }"
        :title="__('Toggle file browser')"
        @click="toggleShowTreeList"
      >
        <icon name="hamburger" />
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
          :start-version="startVersion"
          :target-branch="targetBranch"
          class="mr-version-compare-dropdown"
        />
      </div>
      <div class="inline-parallel-buttons d-none d-md-flex ml-auto">
        <a v-show="hasCollapsedFile" class="btn btn-default append-right-8" @click="expandAllFiles">
          {{ __('Expand all') }}
        </a>
        <a :href="toggleWhitespacePath" class="btn btn-default qa-toggle-whitespace">
          {{ toggleWhitespaceText }}
        </a>
        <div class="btn-group prepend-left-8">
          <button
            id="inline-diff-btn"
            :class="{ active: isInlineView }"
            type="button"
            class="btn js-inline-diff-button"
            data-view-type="inline"
            @click="setInlineDiffViewType"
          >
            {{ __('Inline') }}
          </button>
          <button
            id="parallel-diff-btn"
            :class="{ active: isParallelView }"
            type="button"
            class="btn js-parallel-diff-button"
            data-view-type="parallel"
            @click="setParallelDiffViewType"
          >
            {{ __('Side-by-side') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
